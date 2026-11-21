{
  den.aspects.sphoono.desktop.wm.supporting = {
    homeManager = {
      programs.mpv.enable = true;
      xdg.mimeApps.defaultApplications =
        let
          videoPlayer = [ "mpv.desktop" ];
        in
        {
          "audio/flac" = videoPlayer;
          "audio/mp3" = videoPlayer;
          "audio/mpeg" = videoPlayer;
          "audio/ogg" = videoPlayer;
          "audio/vorbis" = videoPlayer;
          "audio/x-flac" = videoPlayer;
          "audio/x-mp3" = videoPlayer;
          "audio/x-vorbis+ogg" = videoPlayer;
          "audio/wav" = videoPlayer;
          "audio/x-wav" = videoPlayer;
          "audio/aac" = videoPlayer;
          "audio/x-aac" = videoPlayer;
          "audio/m4a" = videoPlayer;
          "audio/x-m4a" = videoPlayer;

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
        };
    };
  };
}
