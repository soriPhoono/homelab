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
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.jellyfin.enable = true;

        systemd.services.jellyfin.serviceConfig = {
          ProtectSystem = "strict";
          ProtectHome = true;
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
            throttleTranscoding = true;
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
    ]);
  }
