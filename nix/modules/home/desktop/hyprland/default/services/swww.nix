{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        swww
      ];

      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "uwsm app -s s -t service swww-daemon &"
        ];
      };
    };
  }
