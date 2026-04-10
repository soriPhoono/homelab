{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.players.video.vlc;
in
  with lib; {
    options.userapps.desktop.players.video.vlc = {
      enable = mkEnableOption "VLC media player";

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default video player. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        vlc
      ];

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        videoPlayer = ["vlc.desktop"];
      in
        mkOverride cfg.priority {
          "video/webm" = videoPlayer;
          "video/x-matroska" = videoPlayer;
          "video/x-flv" = videoPlayer;
          "video/avi" = videoPlayer;
          "video/mp4" = videoPlayer;
          "video/mpeg" = videoPlayer;
          "video/ogg" = videoPlayer;
          "video/quicktime" = videoPlayer;
          "video/x-msvideo" = videoPlayer;
          "video/x-ms-wmv" = videoPlayer;
          "video/3gpp" = videoPlayer;
          "video/3gpp2" = videoPlayer;
        });
    };
  }
