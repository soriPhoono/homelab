{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.players.imv;
in
  with lib; {
    options.userapps.desktop.players.imv = {
      enable = mkEnableOption "imv";

      priority = mkOption {
        type = types.int;
        default = 0;
        description = "Priority for being the default image viewer. Lower is higher priority.";
      };
    };

    config = mkIf cfg.enable {
      programs.imv.enable = true;

      xdg.mimeApps.defaultApplications = lib.mkIf config.userapps.defaultApplications.enable (let
        imageViewer = ["imv.desktop"];
      in
        mkOverride cfg.priority {
          "image/bmp" = imageViewer;
          "image/gif" = imageViewer;
          "image/jpeg" = imageViewer;
          "image/jpg" = imageViewer;
          "image/pjpeg" = imageViewer;
          "image/png" = imageViewer;
          "image/tiff" = imageViewer;
          "image/x-bmp" = imageViewer;
          "image/x-pcx" = imageViewer;
          "image/x-png" = imageViewer;
          "image/x-portable-anymap" = imageViewer;
          "image/x-portable-bitmap" = imageViewer;
          "image/x-portable-graymap" = imageViewer;
          "image/x-portable-pixmap" = imageViewer;
          "image/x-tga" = imageViewer;
          "image/x-xbitmap" = imageViewer;
          "image/heic" = imageViewer;
          "image/avif" = imageViewer;
          "image/webp" = imageViewer;
        });
    };
  }
