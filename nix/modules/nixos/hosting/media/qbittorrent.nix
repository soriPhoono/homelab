{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.qbittorrent;
in
  with lib; {
    options.hosting.media.qbittorrent = {
      enable = mkEnableOption "Enable qBittorrent BitTorrent client";
    };

    config = mkIf cfg.enable {
      services.qbittorrent = {
        enable = true;
        webuiPort = 8080;
        openFirewall = false;
      };

      systemd.services.qbittorrent.serviceConfig = {
        ProtectSystem = lib.mkForce "strict";
        ProtectHome = lib.mkForce true;
        PrivateDevices = true;
        StateDirectory = "qBittorrent";
        ReadWritePaths = ["/mnt/local/media"];
      };

      users = {
        groups.media.members = [config.services.qbittorrent.user];
      };
    };
  }
