{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.tools.docker;
in
  with lib; {
    options.desktop.tools.docker = {
      enable = mkEnableOption "Enable docker container hosting";

      extraSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Extra settings for docker backend";
      };

      networks = mkOption {
        type = with types; listOf str;
        default = [];
        description = "List of Docker networks to automatically create. This is outside of what is mentioned in the oci-containers entries.";
      };

      plugins = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "The name/alias of the plugin";
            };
            image = lib.mkOption {
              type = lib.types.str;
              description = "The container image of the plugin (e.g., grafana/loki-docker-driver:latest)";
            };
            grantAllPermissions = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Automatically grant all requested permissions during install";
            };
          };
        });
        default = [];
        description = "List of Docker plugins to automatically install and enable.";
      };
    };

    config = mkIf cfg.enable {
      systemd.services =
        {
          docker-create-networks = let
            networks = unique (
              flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
            );
          in {
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-create-networks";
                runtimeInputs = with pkgs; [
                  docker
                ];
                text = lib.optionalString (networks != []) ''
                  EXISTING_NETWORKS=$(docker network ls --format '{{.Name}}')
                  ${lib.concatStringsSep "\n" (lib.map (network: ''
                      if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                        docker network create "${network}"
                      fi
                    '')
                    networks)}
                '';
              }}/bin/docker-create-networks";
            };
          };

          docker-install-plugins = {
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellApplication {
                name = "docker-install-plugins";
                runtimeInputs = with pkgs; [
                  docker
                ];
                text = lib.optionalString (cfg.plugins != []) ''
                  EXISTING_PLUGINS=$(docker plugin ls --format '{{.PluginReference}}')
                  ${lib.concatStringsSep "\n" (lib.map (plugin: ''
                      # Ensure plugin is installed
                      if ! echo "$EXISTING_PLUGINS" | grep -Fxq "${plugin.name}"; then
                        docker plugin install ${plugin.image} --alias ${plugin.name} ${lib.optionalString plugin.grantAllPermissions "--grant-all-permissions"}
                      fi
                      # Ensure plugin is enabled
                      if ! docker plugin ls --format '{{.PluginReference}} {{.Enabled}}' | grep -Fxq "${plugin.name} true"; then
                        docker plugin enable ${plugin.name} || true
                      fi
                    '')
                    cfg.plugins)}
                '';
              }}/bin/docker-install-plugins";
            };
          };
        }
        // (lib.listToAttrs (lib.mapAttrsToList (name: _: {
            name = "docker-${name}";
            value = {
              after = ["${networkServiceName}.service" "${pluginServiceName}.service"];
              bindsTo = ["${networkServiceName}.service" "${pluginServiceName}.service"];
            };
          })
          config.virtualisation.oci-containers.containers));

      virtualisation = {
        oci-containers.backend = "docker";
        docker = {
          enable = true;
          autoPrune.enable = true;
          daemon.settings = cfg.extraSettings;
        };
      };

      users.extraUsers =
        lib.mapAttrs (_name: _user: {
          extraGroups = ["docker"];
        })
        (lib.filterAttrs (_name: user: user.admin) config.core.users);

      home-manager.users =
        mapAttrs (_: _: {
          programs.lazydocker.enable = true;
        })
        config.core.users;
    };
  }
