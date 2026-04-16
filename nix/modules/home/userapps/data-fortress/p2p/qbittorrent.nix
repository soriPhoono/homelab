{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.p2p.qbittorrent;
in
  with lib; {
    options.userapps.data-fortress.p2p.qbittorrent = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable qbittorrent.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.qbittorrent];
    };
  }
