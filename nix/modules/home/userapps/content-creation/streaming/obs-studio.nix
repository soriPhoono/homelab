{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.streaming.obs-studio;
in
  with lib; {
    options.userapps.content-creation.streaming.obs-studio = {
      enable = mkEnableOption "Enable obs-studio streaming software";

      package = mkOption {
        type = types.package;
        default = pkgs.obs-studio;
        description = "OBS Studio package to use";
      };

      plugins = mkOption {
        type = with types; listOf package;
        default = [];
        description = "List of obs-studio plugins to install";
      };
    };

    config = mkIf cfg.enable {
      programs.obs-studio = {
        inherit (cfg) enable package;

        plugins = with pkgs.obs-studio-plugins;
          [
            # Hardware Acceleration
            obs-vaapi

            # Capture methods
            obs-pipewire-audio-capture # Pipewire audio capture
            obs-vkcapture # Vulkan
            input-overlay # Gamepad overlay

            # Filters
            obs-backgroundremoval
            pixel-art
          ]
          ++ cfg.plugins;
      };
    };
  }
