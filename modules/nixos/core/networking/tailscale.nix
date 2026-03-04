{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.core.networking.tailscale;
in
  with lib; {
    options.core.networking.tailscale = {
      enable = mkEnableOption "Enable tailscale always on vpn";

      auth = {
        enable = mkEnableOption "Enable tailscale authkey auto login";
        internal = mkEnableOption "Enable internal provisioning of the required secret for authentication";
      };

      service = {
        exposure = mkOption {
          type = with types; enum ["serve" "funnel"];
          default = null;
          description = "How much exposure to give the service, tailnet only or public internet accessable";
          example = "funnel";
        };
        port = mkOption {
          type = with types; nullOr port;
          default = null;
          description = "The port to expose on this device's magic dns subdomain";
          example = 9000;
        };
      };
    };

    config = lib.mkIf cfg.enable (mkMerge [
      {
        networking.firewall.checkReversePath = "loose";

        services.tailscale = {
          enable = true;

          useRoutingFeatures = "both";

          openFirewall = true;

          extraDaemonFlags = [
            "--no-logs-no-support"
          ];
        };

        systemd.services = {
          tailscale-autoconnect = mkIf cfg.auth.enable {
            description = "Configure tailscale authorization";
            after = ["network-pre.target" "tailscale.service"];
            wants = ["network-pre.target" "tailscale.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = mkMerge [
              {
                Type = "oneshot";
              }
              (mkIf cfg.auth.internal (lib.optionalAttrs (options ? sops) {
                EnvironmentFile = config.sops.templates."tailscale.env".path;
              }))
              (mkIf (!cfg.auth.internal) {
                EnvironmentFile = "/var/lib/tailscale/authkey";
              })
            ];
            script = "${pkgs.writeShellApplication {
              name = "tailscale-autoconnect.sh";
              runtimeInputs = with pkgs; [
                tailscale
                jq
              ];
              text = ''
                if [ "$(tailscale status -json | jq -r .BackendState)" = "Running" ]; then
                  exit 0
                fi

                echo "Not logged in. Authenticating with Tailscale..."

                tailscale up --authkey="$TS_AUTHKEY" --accept-dns --exit-node-allow-lan-access
              '';
            }}/bin/tailscale-autoconnect.sh";
          };
          tailscale-serve-init = mkIf (cfg.service.port != null && cfg.service.exposure == "serve") {
            description = "Configure tailscale serve setup after tailscale has been logged-in";
            after = ["tailscale-autoconnect.service"];
            wants = ["tailscale-autoconnect.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
            };
            script = "${pkgs.writeShellApplication {
              name = "tailscale-serve-init.sh";
              runtimeInputs = with pkgs; [
                tailscale
              ];
              text = ''
                # Apply the config from the variable
                if tailscale serve --bg ${cfg.service.port} >/dev/null 2>&1; then
                   echo "Serve configuration applied successfully."
                else
                   echo "Failed to apply Serve configuration."
                   exit 1
                fi
              '';
            }}/bin/tailscale-serve-init.sh";
          };
          tailscale-funnel-init = mkIf (cfg.service.port != null && cfg.service.exposure == "funnel") {
            description = "Configure tailscale funnel setup after tailscale has been logged-in";
            after = ["tailscale-autoconnect.service"];
            wants = ["tailscale-autoconnect.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
            };
            script = "${pkgs.writeShellApplication {
              name = "tailscale-funnel-init.sh";
              runtimeInputs = with pkgs; [
                tailscale
              ];
              text = ''
                # Apply the config from the variable
                if tailscale funnel --bg ${cfg.service.port} >/dev/null 2>&1; then
                  echo "Funnel configuration applied successfully."
                else
                  echo "Failed to apply Funnel configuration."
                  exit 1
                fi
              '';
            }}/bin/tailscale-funnel-init.sh";
          };
        };
      }
      (lib.optionalAttrs (options ? sops) {
        sops = mkIf cfg.auth.internal {
          secrets."networking/tailscale/auth_key" = {};
          templates."tailscale.env".content = ''
            TS_AUTHKEY=${config.sops.placeholder."networking/tailscale/auth_key"}
          '';
        };
      })
    ]);
  }
