{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    config = mkIf cfg.enable {
      desktop.hyprland = {
        hotkeys = {
          terminal = {
            mods = [
              "SUPER"
            ];
            trigger = "Return";
            executor = "exec";
            command = "uwsm app -s a ${config.programs.kitty.package}/bin/kitty";
          };
        };
      };

      userapps.development.terminal.kitty.enable = true;
    };
  }
