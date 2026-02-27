{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.single-node.backends.docker;
in
  with lib; {
    options.hosting.single-node.backends.docker = {
      enable = lib.mkEnableOption "docker backend";

      extraSettings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = {};
        description = "Extra settings for docker backend";
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

    config = lib.mkIf cfg.enable (let
      invocation = pkgs.docker;
      networkServiceName = "docker-create-networks";
      pluginServiceName = "docker-install-plugins";
    in {
      assertions = [
        {
          assertion = !config.hosting.single-node.backends.podman.enable;
          message = "Cannot enable both docker and podman backends";
        }
      ];

      systemd.services =
        {
          "${networkServiceName}" = let
            networks = unique (
              flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
            );
          in {
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScriptBin "${networkServiceName}" ''
                ${lib.optionalString (networks != []) ''
                  EXISTING_NETWORKS=$(${invocation}/bin/docker network ls --format '{{.Name}}')
                  ${lib.concatStringsSep "\n" (lib.map (network: ''
                      if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                        ${invocation}/bin/docker network create "${network}"
                      fi
                    '')
                    networks)}
                ''}
              ''}/bin/${networkServiceName}";
            };
          };

          "${pluginServiceName}" = {
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScriptBin pluginServiceName ''
                ${lib.optionalString (cfg.plugins != []) ''
                  EXISTING_PLUGINS=$(${invocation}/bin/docker plugin ls --format '{{.PluginReference}}')
                  ${lib.concatStringsSep "\n" (lib.map (plugin: ''
                      if ! echo "$EXISTING_PLUGINS" | grep -Fxq "${plugin.name}"; then
                        ${invocation}/bin/docker plugin install ${plugin.image} --alias ${plugin.name} ${lib.optionalString plugin.grantAllPermissions "--grant-all-permissions"}
                      fi
                      # Ensure plugin is enabled
                      if ! ${invocation}/bin/docker plugin ls --format '{{.PluginReference}} {{.Enabled}}' | grep -Fxq "${plugin.name} true"; then
                        ${invocation}/bin/docker plugin enable ${plugin.name} || true
                      fi
                    '')
                    cfg.plugins)}
                ''}
              ''}/bin/${pluginServiceName}";
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

      virtualisation.docker = {
        enable = true;
        autoPrune.enable = true;
        daemon.settings = cfg.extraSettings;
      };

      virtualisation.oci-containers.backend = "docker";

      users.extraUsers =
        lib.mapAttrs (_name: _user: {
          extraGroups = ["docker"];
        })
        (lib.filterAttrs (_name: user: user.admin) config.core.users);
    });
  }
