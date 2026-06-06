{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      # Start the Noctalia shell and user autostart apps on Hyprland launch
      wayland.windowManager.hyprland.settings.on = {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              ${concatStringsSep "\n" (map (invocation: ''
                hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app ${invocation}")
              '')
              cfg.autostart)}
            end
          '')
        ];
      };
    };
  }
