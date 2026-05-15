{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      personal.noctalia = {
        enable = true;
        monitors = mkDefault (map (monitor: monitor.name) (filter (monitor: monitor.primary) cfg.monitors));
      };

      wayland.windowManager.hyprland.settings.on = {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -s b -t service noctalia-shell")
              ${concatStringsSep "\n              " (map (cmd: ''hl.exec_cmd("${cmd}")'') cfg.autostart)}
            end
          '')
        ];
      };
    };
  }
