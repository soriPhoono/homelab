{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings.bind = [
        "SUPER, Return, exec, uwsm app -s a kitty"
      ];

      userapps.development.terminal.kitty.enable = true;
    };
  }
