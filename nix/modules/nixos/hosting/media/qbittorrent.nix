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
        openFirewall = true;
      };

      users = {
        groups.media.members = [config.services.qbittorrent.user];
      };
    };
  }
