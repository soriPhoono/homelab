{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.pcmanfm;
in
  with lib; {
    options.userapps.desktop.file-browser.pcmanfm = {
      enable = mkEnableOption "pcmanfm file browser";
    };

    config = mkIf cfg.enable {
      home.sessionVariables.FILE_BROWSER = "pcmanfm";

      xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications {
        "inode/directory" = ["pcmanfm.desktop"];
      };

      home.packages = [
        pkgs.pcmanfm
      ];
    };
  }
