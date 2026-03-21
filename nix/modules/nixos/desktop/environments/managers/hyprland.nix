{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.environments.managers.hyprland;
in
  with lib; {
    options.desktop.environments.managers.hyprland = {
      enable = mkEnableOption "Enable hyprland desktop environment.";
    };

    config = mkIf cfg.enable {
      desktop.environments = {
        managers.enable = true;
        display_managers.greetd.enable = config.desktop.environment == null;
      };

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      home-manager.users =
        builtins.mapAttrs (_: _: {
          desktop.environments.hyprland.enable = true;
        })
        config.core.users;
    };
  }
