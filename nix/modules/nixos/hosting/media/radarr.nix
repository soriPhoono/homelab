{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.radarr;
in
  with lib; {
    options.hosting.media.radarr = {
      enable = mkEnableOption "Enable Radarr movie downloader";
    };

    config = mkIf cfg.enable {
      services.radarr.enable = true;

      systemd.services.radarr.serviceConfig = {
        ProtectSystem = lib.mkForce "strict";
        ProtectHome = lib.mkForce true;
        PrivateDevices = true;
        StateDirectory = "radarr";
        ReadWritePaths = ["/mnt/local/media"];
      };

      users = {
        groups.media.members = [config.services.radarr.user];
      };
    };
  }
