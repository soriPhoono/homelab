{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.video-players.vlc;
in
  with lib; {
    options.userapps.desktop.video-players.vlc = {
      enable = mkEnableOption "VLC media player";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        vlc
      ];
    };
  }
