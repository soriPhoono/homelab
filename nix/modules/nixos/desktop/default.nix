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
      desktop.services = {
        pipewire.enable = true;
        flatpak.enable = true;
      };

      xdg.terminal-exec.enable = true;

      programs.appimage = {
        enable = true;
        binfmt = true;
      };

      services = {
        geoclue2.enable = true;
        automatic-timezoned.enable = true;
        dbus.implementation = "broker";
      };
    };
  }
