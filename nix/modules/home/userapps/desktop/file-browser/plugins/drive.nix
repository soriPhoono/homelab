{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.plugins.drive;
in
  with lib; {
    options.userapps.desktop.file-browser.plugins.drive = {
      enable = mkEnableOption "Enable drive plugin for file browser";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        insync
      ];
    };
  }
