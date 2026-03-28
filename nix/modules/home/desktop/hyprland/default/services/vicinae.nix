{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      programs.vicinae.enable = true;

      wayland.windowManager.hyprland.settings = {
        exec-once = [
          "uwsm app -s s -t service vicinae server"
        ];

        bind = [
          "SUPER, A, exec, vicinae toggle"
        ];
      };
    };
  }
