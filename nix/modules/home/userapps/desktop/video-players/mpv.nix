{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.videoPlayers.mpv;
in
  with lib; {
    options.userapps.desktop.videoPlayers.mpv = {
      enable = mkEnableOption "Enable mpv, the light-weight video player";
      priority = mkOption {
        type = types.int;
        default = 0;
        description = "The priority of mpv, the light-weight video player. Lower priority means it will be preferred over other video players.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.mpv];

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        videoPlayer = ["mpv.desktop"];
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
