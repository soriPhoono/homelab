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
        extra-substituters = ["https://noctalia.cachix.org"];
        extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
      };

      core = {
        hardware.bluetooth.enable = true;
        networking.network-manager.enable = true;
      };

      desktop.environments = {
        managers.enable = true;
        display_managers.sddm.enable = true;
      };

      environment.sessionVariables = {
        NIXOS_OZONE_WL = "1";
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
        power-profiles-daemon.enable = true;
        acpid = {
          enable = true;
          logEvents = true;
          powerEventCommands = "systemctl poweroff";

          handlers = {
            ac-power = {
              action = ''
                STATUS=$(cat /sys/class/power_supply/*/online 2>/dev/null | head -n 1)

                if [ "$STATUS" -eq 1 ]; then
                  ${pkgs.logger}/bin/logger "ACPI Event: AC connected. Setting profile to balanced."
                  ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance
                else
                  ${pkgs.logger}/bin/logger "ACPI Event: AC disconnected. Setting profile to power-saver."
                  ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced
                fi
              '';
              event = "ac_adapter/*";
            };
          };
        };
        upower = {
          enable = true;
          criticalPowerAction = "PowerOff";
        };

        gvfs.enable = true;
        gnome.evolution-data-server.enable = true;
      };

      home-manager.users =
        builtins.mapAttrs (_: _: {
          home.sessionVariables = {
            SSH_AUTH_SOCK = mkDefault "$XDG_RUNTIME_DIR/ssh-agent";
          };
        })
        config.core.users;
    };
  }
