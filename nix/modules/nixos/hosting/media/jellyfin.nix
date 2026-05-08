{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.jellyfin;
in
  with lib; {
    options.hosting.media.jellyfin = {
      enable = mkEnableOption "Enable Jellyfin media server for edge device media archiving";
      acceleration.enable = mkEnableOption "Enable hardware acceleration (VAAPI) on the integrated GPU";
      tailscaleServe.enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Expose Jellyfin on the Tailscale network via Tailscale Serve: HTTPS on port 443 of this machine's tailnet address,
          terminating TLS and proxying to Jellyfin's HTTP listener on loopback (implemented by NixOS
          {option}`services.tailscale.serve`, which runs `tailscale serve set-config`).
          Other tailnet devices should open `https://` plus this machine's Tailscale name (same idea as `networking.hostName` / MagicDNS).
        '';
      };

      tailscaleServe.allowDirectHttpOnTailnet = mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, opens Jellyfin's HTTP port (8096) on the Tailscale interface in addition to HTTPS via Serve.
          Leave false so tailnet clients use only the HTTPS endpoint (recommended).
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.jellyfin.enable = true;

        systemd.services.jellyfin.serviceConfig = {
          ProtectSystem = lib.mkForce "strict";
          ProtectHome = lib.mkForce true;
          StateDirectory = "jellyfin";
          CacheDirectory = "jellyfin";
          ReadWritePaths = ["/mnt/local/media"];
        };
      }
      (mkIf cfg.acceleration.enable {
        services.jellyfin = {
          forceEncodingConfig = true;
          hardwareAcceleration = {
            enable = true;
            device = "/dev/dri/renderD128";
            type =
              if config.core.hardware.gpu.intel.integrated.enable
              then "qsv"
              else "vaapi";
          };
          transcoding = {
            enableHardwareEncoding = true;
            enableIntelLowPowerEncoding = config.core.hardware.gpu.intel.integrated.enable;
            throttleTranscoding = false;
            hardwareEncodingCodecs.hevc = true;
            hardwareDecodingCodecs = {
              h264 = true;
              hevc = true;
            };
          };
        };

        # Ensure the jellyfin user has access to graphics hardware
        users = {
          groups.media.members = ["jellyfin"];
          users.jellyfin = {
            extraGroups = ["video" "render"];
          };
        };
      })
      (mkIf (
          cfg.tailscaleServe.enable
          && config.core.networking.tailscale.enable
        ) {
          core.networking.tailscale.serve = {
            enable = lib.mkDefault true;
            services.jellyfin.proxy = {
              # Equivalent CLI idea: tailscale serve --https=443 http://127.0.0.1:8096
              # TLS is terminated by Tailscale; Jellyfin sees plain HTTP from loopback.
              "tcp:443" = "http://127.0.0.1:8096";
            };
          };

          systemd.services.jellyfin = {
            after = ["tailscale-serve.service"];
            wants = ["tailscale-serve.service"];
          };

          networking.firewall.interfaces.${config.services.tailscale.interfaceName}.allowedTCPPorts =
            lib.mkIf cfg.tailscaleServe.allowDirectHttpOnTailnet [8096];
        })
    ]);
  }
