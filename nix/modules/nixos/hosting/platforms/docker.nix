{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.platforms.docker;
in
  with lib; {
    options.hosting.platforms.docker = {
      enable = mkEnableOption "Enable docker container hosting";

      extraSettings = mkOption {
        type = types.attrsOf types.anything;
        default = {};
        description = "Extra settings for docker backend";
      };

      networks = mkOption {
        type = with types; listOf str;
        default = [];
        description = "List of Docker networks to automatically create. This is outside of what is mentioned in the oci-containers entries.";
      };

      plugins = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "The name/alias of the plugin";
              };
              image = mkOption {
                type = types.str;
                description = "The container image of the plugin (e.g., grafana/loki-docker-driver:latest)";
              };
              grantAllPermissions = mkOption {
                type = types.bool;
                default = true;
                description = "Automatically grant all requested permissions during install";
              };
            };
          }
        );
        default = [];
        description = "List of Docker plugins to automatically install and enable.";
      };

      tailscaleBypass = {
        enable = mkOption {
          type = types.bool;
          default = config.core.networking.tailscale.enable or false;
          description = "Whether to automatically bypass Tailscale routing for Docker subnets.";
        };

        subnets = mkOption {
          type = types.listOf types.str;
          default = [
            "172.16.0.0/12"
            "10.0.0.0/8"
            "192.168.0.0/16"
          ];
          description = "List of subnets to bypass Tailscale routing for (to only). 'from' rules are intentionally omitted so outbound traffic from private IPs (Docker containers, host) routes through the Tailscale exit node.";
        };

        priority = mkOption {
          type = types.int;
          default = 2500;
          description = "The priority of the ip rules (must be lower than 5270 to take precedence).";
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
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
                RemainAfterExit = true;
                ExecStart = "${
                  pkgs.writeShellApplication {
                    name = "docker-create-networks";
                    runtimeInputs = with pkgs; [
                      docker
                    ];
                    text = optionalString (networks != []) ''
                      EXISTING_NETWORKS=$(docker network ls --format '{{.Name}}')
                      ${concatStringsSep "\n" (
                        map (network: ''
                          if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                            docker network create "${network}"
                          fi
                        '')
                        networks
                      )}
                    '';
                  }
                }/bin/docker-create-networks";
              };
            };

            docker-install-plugins = {
              after = ["docker.service"];
              wantedBy = ["multi-user.target"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${
                  pkgs.writeShellApplication {
                    name = "docker-install-plugins";
                    runtimeInputs = with pkgs; [
                      docker
                      gnugrep
                    ];
                    text = optionalString (cfg.plugins != []) ''
                      ${concatStringsSep "\n" (
                        map (plugin: ''
                          # Check if plugin already exists by alias
                          CURRENT_REF=$(docker plugin inspect "${plugin.name}" --format '{{.PluginReference}}' 2>/dev/null || true)

                          if [ -n "$CURRENT_REF" ]; then
                            if [ "$CURRENT_REF" = "${plugin.image}" ]; then
                              echo "Plugin ${plugin.name} is up to date (${plugin.image})"
                            else
                              echo "Plugin ${plugin.name} version mismatch ($CURRENT_REF -> ${plugin.image}). Migrating..."
                              docker plugin disable "${plugin.name}" --force
                              docker plugin rm "${plugin.name}" --force
                              docker plugin install ${plugin.image} --alias ${plugin.name} ${optionalString plugin.grantAllPermissions "--grant-all-permissions"}
                            fi
                          else
                            echo "Installing plugin ${plugin.name} (${plugin.image})..."
                            docker plugin install ${plugin.image} --alias ${plugin.name} ${optionalString plugin.grantAllPermissions "--grant-all-permissions"}
                          fi

                          # Ensure plugin is enabled
                          if ! docker plugin ls --format '{{.Name}} {{.Enabled}}' | grep -Fxq "${plugin.name} true"; then
                            echo "Enabling plugin ${plugin.name}..."
                            docker plugin enable "${plugin.name}" || true
                          fi
                        '')
                        cfg.plugins
                      )}
                    '';
                  }
                }/bin/docker-install-plugins";
              };
            };

            docker-tailscale-bypass = mkIf cfg.tailscaleBypass.enable {
              description = "Bypass Tailscale routing for Docker traffic (watchdog)";
              wants = [
                "network-online.target"
                "tailscaled.service"
              ];
              bindsTo = ["tailscaled.service"];
              after = [
                "network-online.target"
                "tailscaled.service"
                "docker.service"
              ];
              wantedBy = [
                "multi-user.target"
                "tailscaled.service"
              ];
              serviceConfig = {
                Type = "simple";
                Restart = "always";
                RestartSec = 10;
                ExecStart = "${
                  pkgs.writeShellApplication {
                    name = "docker-tailscale-bypass-watchdog";
                    runtimeInputs = with pkgs; [
                      iproute2
                      gnugrep
                    ];
                    text = ''
                      apply_rules() {
                        ${concatStringsSep "
                      " (
                          flatten (
                            map (subnet: [
                              ''
                                if ! ip rule show priority ${toString cfg.tailscaleBypass.priority} | grep -q "to ${subnet} lookup main"; then
                                  echo "Adding bypass rule to ${subnet}..."
                                  ip rule add to ${subnet} lookup main prio ${toString cfg.tailscaleBypass.priority}
                                fi
                              ''
                            ])
                            cfg.tailscaleBypass.subnets
                          )
                        )}
                      }

                      # Initial application — retry until rules persist
                      for _ in $(seq 1 10); do
                        apply_rules
                        if ip rule show priority ${toString cfg.tailscaleBypass.priority} | grep -q "to"; then
                          break
                        fi
                        sleep 3
                      done

                      # Watchdog loop: re-apply every 15s if tailscale wipes them
                      while true; do
                        sleep 15
                        apply_rules
                      done
                    '';
                  }
                }/bin/docker-tailscale-bypass-watchdog";

                ExecStop = "${
                  pkgs.writeShellApplication {
                    name = "docker-tailscale-bypass-stop";
                    runtimeInputs = with pkgs; [
                      iproute2
                      gnugrep
                    ];
                    text = ''
                      ${concatStringsSep "\n" (
                        flatten (
                          map (subnet: [
                            ''
                              if ip rule show priority ${toString cfg.tailscaleBypass.priority} | grep -q "to ${subnet} lookup main"; then
                                echo "Removing bypass rule to ${subnet}..."
                                ip rule del to ${subnet} lookup main prio ${toString cfg.tailscaleBypass.priority}
                              fi
                            ''
                          ])
                          cfg.tailscaleBypass.subnets
                        )
                      )}
                    '';
                  }
                }/bin/docker-tailscale-bypass-stop";
              };
            };
          }
          // (listToAttrs (
            mapAttrsToList (name: _: {
              name = "docker-${name}";
              value = {
                after = [
                  "docker-create-networks.service"
                  "docker-install-plugins.service"
                ];
                bindsTo = [
                  "docker-create-networks.service"
                  "docker-install-plugins.service"
                ];
              };
            })
            config.virtualisation.oci-containers.containers
          ));

        virtualisation = {
          oci-containers.backend = "docker";
          docker = {
            enable = true;
            autoPrune.enable = true;
            daemon.settings =
              {
                dns = [
                  "1.1.1.1"
                  "1.0.0.1"
                ];
              }
              // cfg.extraSettings;
          };
        };

        users.extraUsers = mapAttrs (_name: _user: {
          extraGroups = ["docker"];
        }) (filterAttrs (_name: user: user.admin) config.core.users);

        home-manager.users =
          mapAttrs (_: _: {
            programs.lazydocker.enable = true;
          })
          config.core.users;
      }
    ]);
  }
