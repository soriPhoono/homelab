{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.file-browser.nautilus;
in
  with lib; {
    options.userapps.desktop.file-browser.nautilus = {
      enable = mkEnableOption "Enable Nautilus file browser";

      priority = mkOption {
        type = types.int;
        default = 0;
        description = "Priority for being the default file browser. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      home.sessionVariables.FILE_BROWSER = mkOverride cfg.priority "nautilus";

      xdg.mimeApps.defaultApplications = mkIf config.userapps.defaultApplications.enable (let
        fileBrowser = ["org.gnome.Nautilus.desktop"];
      in
        mkOverride cfg.priority {
          "inode/directory" = fileBrowser;
          "application/x-gnome-saved-search" = fileBrowser;
        });

      home.packages = [
        pkgs.nautilus
        pkgs.file-roller
      ];
    };
  }
