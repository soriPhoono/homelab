# NOTE: cosmic in nixpkgs is not stable yet: https://github.com/NixOS/nixpkgs/issues/259641
{
  lib,
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
      desktop.enable = true;

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          COSMIC_DATA_CONTROL_ENABLED = 1;
        };
      };

      services = {
        system76-scheduler.enable = true;

        desktopManager.cosmic.enable = true;
      };
    };
  }
