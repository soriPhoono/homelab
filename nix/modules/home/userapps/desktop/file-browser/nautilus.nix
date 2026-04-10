{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.nautilus;
in
  with lib; {
    options.userapps.desktop.file-browser.nautilus.enable = mkEnableOption "Nautilus file browser";

    config = mkIf cfg.enable {
      home.sessionVariables.FILE_BROWSER = "nautilus";

      xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications {
        "inode/directory" = ["nautilus.desktop"];
      };

      home.packages = with pkgs; [
        nautilus
      ];
    };
  }
