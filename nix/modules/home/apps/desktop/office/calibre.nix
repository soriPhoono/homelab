{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.office.calibre;
in
  with lib; {
    options.apps.desktop.office.calibre = {
      enable = mkEnableOption "Enable Calibre ebook management application";
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.calibre];
    };
  }
