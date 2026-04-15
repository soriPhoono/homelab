{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.libreoffice;
in
  with lib; {
    options.userapps.desktop.office.libreoffice = {
      enable = mkEnableOption "Enable LibreOffice desktop suite";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.libreoffice-fresh
        pkgs.hunspell
        pkgs.hunspellDicts.en_US
      ];
    };
  }
