{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.players.audio.rhythmbox;
in
  with lib; {
    options.userapps.desktop.players.audio.rhythmbox = {
      enable = mkEnableOption "Rhythmbox, the GNOME audio player";

      priority = mkOption {
        type = types.int;
        default = 10;
        description = "Priority for being the default audio player. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.rhythmbox];

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        audioPlayer = ["rhythmbox.desktop"];
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
        });
    };
  }
