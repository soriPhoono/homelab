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
        display_managers.sddm.enable = true;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
      };

      programs.hyprland = {
        enable = true;
        withUWSM = true;
      };

      services = {
        blueman.enable = true;
        power-profiles-daemon.enable = true;
      };

      home-manager.users =
        builtins.mapAttrs (_: _: {
          desktop.hyprland.enable = true;

          home.sessionVariables = {
            SSH_AUTH_SOCK = mkDefault "$XDG_RUNTIME_DIR/ssh-agent";
          };
        })
        config.core.users;
    };
  }
