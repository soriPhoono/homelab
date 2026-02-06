{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.environments.managers;
in
  with lib; {
    imports = [
      ./hyprland
    ];

    options.desktop.environments.managers = {
      enable = mkEnableOption "Enable hyprland desktop environment.";
    };

    config = mkIf cfg.enable {
      desktop = {
        environments.uwsm.enable = true;
      };
    };
  }
