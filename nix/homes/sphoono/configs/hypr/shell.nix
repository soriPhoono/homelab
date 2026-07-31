{
  lib,
  pkgs,
  config,
  ...
}: let
  hyprCfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    config = mkIf hyprCfg.enable {
      home.packages = with pkgs; [
        linux-wallpaperengine
      ];

      desktop.window-managers.shells.noctalia = {
        enable = true;

        avatarImage = ../assets/avatar.png;

        wallpaperDir = "${config.home.homeDirectory}/Shared/Pictures/Wallpapers";

        location = {
          name = "Fort Worth, TX";
          useFahrenheit = true;
          use12HourFormat = true;
        };

        settings = {
          "calendar.account.personal_google" = {
            type = "google";
            name = "Personal";
          };
        };

        plugins = {
          enabled = [
            "tadomika_ari/w-engine"
          ];

          sources = [
            {
              name = "official-plugins";
              kind = "git";
              location = "https://github.com/noctalia-dev/official-plugins";
            }
            {
              name = "community-plugins";
              kind = "git";
              location = "https://github.com/noctalia-dev/community-plugins";
            }
          ];
        };
      };
    };
  }
