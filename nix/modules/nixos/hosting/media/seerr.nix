{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.seerr;
in
  with lib; {
    options.hosting.media.seerr = {
      enable = mkEnableOption "Enable Jellyseerr request manager for media hosting";
    };

    config = mkIf cfg.enable {
      services.seerr.enable = true;

      systemd.services.seerr.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
      };
    };
  }
