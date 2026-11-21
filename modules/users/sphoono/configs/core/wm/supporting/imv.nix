{
  den.aspects.sphoono.desktop.wm.supporting = {
    homeManager = {
      programs.imv.enable = true;
      xdg.mimeApps.defaultApplications =
        let
          imageViewer = [ "imv.desktop" ];
        in
        {
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
        };
    };
  };
}
