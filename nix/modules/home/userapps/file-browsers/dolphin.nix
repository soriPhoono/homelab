{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.file-browser.dolphin;
in
  with lib; {
    options.userapps.file-browser.dolphin.enable = mkEnableOption "Enable dolphin file browser";

    config = mkIf cfg.enable {
      home.sessionVariables.FILE_BROWSER = "dolphin";

      xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications {
        "inode/directory" = ["dolphin.desktop"];
      };

      home.packages = with pkgs; [
        kdePackages.dolphin
      ];
    };
  }
