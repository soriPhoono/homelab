{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      programs.waybar = {
        enable = true;

        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 30;
            output = [
              "eDP-1"
            ];
          };
        };
      };

      wayland.windowManager.hyprland.settings.exec-once = [
        "uwsm app -s s -t service waybar"
      ];
    };
  }
