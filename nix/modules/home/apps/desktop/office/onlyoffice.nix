{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.office.onlyoffice;
in
  with lib; {
    options.apps.desktop.office.onlyoffice = {
      enable = mkEnableOption "Enable OnlyOffice desktop editors";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.onlyoffice-desktopeditors
      ];
    };
  }
