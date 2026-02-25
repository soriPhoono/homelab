{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.kde;
in
  with lib; {
    options.desktop.environments.kde = {
      enable = mkEnableOption "Enable kde desktop environment";
    };

    config = mkIf cfg.enable {
      desktop = {
        enable = true;
        environment = "kde";
        environments.display_managers.sddm.enable = true;
      };

      environment = {
        sessionVariables.NIXOS_OZONE_WL = "1";

        systemPackages = with pkgs; [
          kdePackages.discover
          kdePackages.ksystemlog
        ];
      };

      services = {
        desktopManager.plasma6.enable = true;
      };
    };
  }
