# NOTE: cosmic in nixpkgs is not stable yet: https://github.com/NixOS/nixpkgs/issues/259641
{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.cosmic;
in
  with lib; {
    options.desktop.environments.cosmic = {
      enable = mkEnableOption "Enable cosmic desktop";
    };

    config = mkIf cfg.enable {
      desktop = {
        enable = true;
        environment = "cosmic";
      };

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          COSMIC_DATA_CONTROL_ENABLED = 1;
        };

        systemPackages = with pkgs; [
        ];
      };

      programs.firefox.preferences = {
        # disable libadwaita theming for Firefox
        "widget.gtk.libadwaita-colors.enabled" = false;
      };

      services = {
        system76-scheduler.enable = true;

        desktopManager.cosmic.enable = true;
      };
    };
  }
