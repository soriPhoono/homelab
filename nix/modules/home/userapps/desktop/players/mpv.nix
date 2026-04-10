{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.players.mpv;
in
  with lib; {
    options.userapps.desktop.players.mpv = {
      enable = mkEnableOption "Enable mpv, the light-weight video player";
      priority = mkOption {
        type = types.int;
        default = 0;
        description = "The priority of mpv, the light-weight video player. Lower priority means it will be preferred over other video players.";
      };
    };

    config = mkIf cfg.enable {
      programs.mpv.enable = true;

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        videoPlayer = ["mpv.desktop"];
      in
        mkOverride cfg.priority {
          "audio/flac" = audioPlayer;
          "audio/mp3" = audioPlayer;
          "audio/mpeg" = audioPlayer;
          "audio/ogg" = audioPlayer;
          "audio/vorbis" = audioPlayer;
          "audio/x-flac" = audioPlayer;
          "audio/x-mp3" = audioPlayer;
          "audio/x-vorbis+ogg" = audioPlayer;
          "audio/wav" = audioPlayer;
          "audio/x-wav" = audioPlayer;
          "audio/aac" = audioPlayer;
          "audio/x-aac" = audioPlayer;
          "audio/m4a" = audioPlayer;
          "audio/x-m4a" = audioPlayer;

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
