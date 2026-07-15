{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.hosting.platforms.podman;
in
  with lib; {
    options.hosting.platforms.podman = {
      enable = mkEnableOption "Enable podman containerization platform";

      tailscaleBypass = {
        enable = mkOption {
          type = types.bool;
          default = config.core.networking.tailscale.enable or false;
          description = "Whether to automatically bypass Tailscale routing for Podman subnets.";
        };

        subnets = mkOption {
          type = types.listOf types.str;
          default = [
            "172.16.0.0/12"
            "10.0.0.0/8"
            "192.168.0.0/16"
          ];
          description = "List of subnets to bypass Tailscale routing for (to only). 'from' rules are intentionally omitted so outbound traffic from private IPs (Podman containers, host) routes through the Tailscale exit node.";
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
        virtualisation.podman = {
          enable = true;
          autoPrune.enable = true;
          dockerSocket.enable = true;
        };

        systemd.services =
          {
            podman-tailscale-bypass = mkIf cfg.tailscaleBypass.enable {
              description = "Bypass Tailscale routing for Podman traffic (watchdog)";
              wants = [
                "network-online.target"
                "tailscaled.service"
              ];
              bindsTo = ["tailscaled.service"];
              after = [
                "network-online.target"
                "tailscaled.service"
                "podman.service"
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
                    name = "podman-tailscale-bypass-watchdog";
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
                }/bin/podman-tailscale-bypass-watchdog";

                ExecStop = "${
                  pkgs.writeShellApplication {
                    name = "podman-tailscale-bypass-stop";
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
                }/bin/podman-tailscale-bypass-stop";
              };
            };

            podman-create-networks = let
              networks = unique (
                flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
              );
            in {
              after = ["podman.service"];
              wantedBy = ["multi-user.target"];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = "${
                  pkgs.writeShellApplication {
                    name = "podman-create-networks";
                    runtimeInputs = with pkgs; [
                      podman
                    ];
                    text = optionalString (networks != []) ''
                      EXISTING_NETWORKS=$(podman network ls --format '{{.Name}}')
                      ${concatStringsSep "\n" (
                        map (network: ''
                          if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                            podman network create "${network}"
                          fi
                        '')
                        networks
                      )}
                    '';
                  }
                }/bin/podman-create-networks";
              };
            };
          }
          // (listToAttrs (
            mapAttrsToList (name: _: {
              name = "podman-${name}";
              value = {
                after = [
                  "podman-create-networks.service"
                ];
                bindsTo = [
                  "podman-create-networks.service"
                ];
              };
            })
            config.virtualisation.oci-containers.containers
          ));
      }
    ]);
  }
