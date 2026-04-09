{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.onlyoffice;
in
  with lib; {
    options.userapps.desktop.office.onlyoffice = {
      enable = mkEnableOption "Enable OnlyOffice desktop editors";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.onlyoffice-desktopeditors
      ];
    };
  }
