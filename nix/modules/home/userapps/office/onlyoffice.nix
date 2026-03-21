{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.office.onlyoffice;
in
  with lib; {
    options.userapps.office.onlyoffice = {
      enable = mkEnableOption "Enable OnlyOffice desktop editors";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.onlyoffice-desktopeditors
      ];
    };
  }
