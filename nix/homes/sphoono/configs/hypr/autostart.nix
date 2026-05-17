{
  lib,
  pkgs,
  config,
  ...
}: let
  envCfg = config.desktop;
  hyprCfg = envCfg.window-managers.hyprland;
in
  with lib; {
    config = mkIf hyprCfg.enable {
      # Start the Noctalia shell and user autostart apps on Hyprland launch
      wayland.windowManager.hyprland.settings.on = {
        _args = [
          "hyprland.start"
          (lib.generators.mkLuaInline ''
            function()
              ${optionalString (envCfg.window-managers.hyprland.shells.noctalia.enable or false) ''
              hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -s b -t service noctalia-shell")
            ''}
              ${concatStringsSep "\n              " (map (entry: ''
                hl.exec_cmd("${entry.command}")
              '')
              envCfg.xdg.autostart)}
            end
          '')
        ];
      };
    };
  }
