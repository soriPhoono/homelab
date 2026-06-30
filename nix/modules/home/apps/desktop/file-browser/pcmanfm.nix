{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.file-browser.pcmanfm;
in
  with lib; {
    options.apps.desktop.file-browser.pcmanfm = {
      enable = mkEnableOption "pcmanfm file browser";
    };

    config = mkIf cfg.enable {
      home.sessionVariables.FILE_BROWSER = mkOverride cfg.priority "pcmanfm";

      xdg.mimeApps.defaultApplications = mkIf config.apps.defaultApplications.enable {
        "inode/directory" = ["pcmanfm.desktop"];
      };

      home.packages = [
        pkgs.pcmanfm
      ];
    };
  }
