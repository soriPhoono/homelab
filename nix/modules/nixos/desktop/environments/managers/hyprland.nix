{
  lib,
  pkgs,
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
      nix.settings = {
        substituters = ["https://hyprland.cachix.org"];
        trusted-substituters = ["https://hyprland.cachix.org"];
        trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
      };

      desktop.environments = {
        managers.enable = true;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
        GTK_USE_PORTAL = "1";
      };

      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

      security.polkit.enable = true;

      programs = {
        dconf.enable = true;
        hyprland = {
          enable = true;
          withUWSM = true;
        };
      };

      services = {
        gvfs.enable = true;
        gnome.gnome-keyring.enable = true;

        power-profiles-daemon.enable = true;
        upower = {
          enable = true;
          criticalPowerAction = "PowerOff";
        };
      };

      # Enable the home-manager desktop framework for every system user
      home-manager.users =
        builtins.mapAttrs (_: _: {
          imports = [
            (
              {
                config,
                nixosConfig,
                ...
              }: {
                xdg.configFile."uwsm/env".source =
                  mkIf nixosConfig.programs.uwsm.enable "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
              }
            )
          ];

          # Activate the desktop framework: core → WM base → Hyprland
          desktop.window-managers = {
            enable = true;
            hyprland.enable = true;
          };

          home.sessionVariables = {
            SSH_AUTH_SOCK = mkDefault "$XDG_RUNTIME_DIR/ssh-agent";
          };
        })
        config.core.users;
    };
  }
