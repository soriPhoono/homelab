{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.office.calibre;
in
  with lib; {
    options.userapps.desktop.office.calibre = {
      enable = mkEnableOption "Enable Calibre ebook management application";
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.calibre];
    };
  }
