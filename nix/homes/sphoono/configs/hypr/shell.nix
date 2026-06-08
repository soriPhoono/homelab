{
  lib,
  config,
  ...
}: let
  hyprCfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    config = mkIf hyprCfg.enable {
      desktop.window-managers.shells.noctalia = {
        enable = true;

        avatarImage = ../assets/avatar.png;

        wallpaperDir = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";

        location = {
          name = "Fort Worth, TX";
          useFahrenheit = true;
          use12HourFormat = true;
        };
      };
    };
  }
