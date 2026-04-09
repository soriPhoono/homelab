{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.qbittorrent;
in
  with lib; {
    options.userapps.data-fortress.qbittorrent = {
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
