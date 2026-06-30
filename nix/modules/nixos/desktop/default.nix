{
  lib,
  config,
  ...
}: let
  cfg = config.desktop;
in
  with lib; {
    imports = [
      ./environments
      ./features
      ./services
      ./tools
    ];

    options.desktop.enable = mkEnableOption "Enable core desktop configurations";

    config = mkIf cfg.enable {
      xdg.terminal-exec.enable = true;

      services = {
        geoclue2.enable = true;
        dbus.implementation = "broker";
      };

      desktop = {
        tools.appimage.enable = true;
      };
    };
  }
