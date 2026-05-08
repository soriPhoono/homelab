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
          Expose Jellyfin on the Tailscale network via Tailscale Serve (HTTPS on port 443 of the node's tailnet address).
          Phones can open https:// followed by this machine's MagicDNS name (shown in Tailscale clients as the device name).
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
              # Terminate HTTPS on tailnet and proxy to Jellyfin HTTP
              "tcp:443" = "http://127.0.0.1:8096";
            };
          };

          systemd.services.jellyfin = {
            after = ["tailscale-serve.service"];
            wants = ["tailscale-serve.service"];
          };
        })
    ]);
  }
