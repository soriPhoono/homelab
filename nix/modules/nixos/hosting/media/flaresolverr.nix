{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.flaresolverr;
in
  with lib; {
    options.hosting.media.flaresolverr = {
      enable = mkEnableOption "flaresolverr";
    };

    config = mkIf cfg.enable {
      services.flaresolverr.enable = true;

      systemd.services.flaresolverr.serviceConfig = {
        ProtectSystem = "strict";
        ProtectHome = true;
        PrivateDevices = true;
      };
    };
  }
