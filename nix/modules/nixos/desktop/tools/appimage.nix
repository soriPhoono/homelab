{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.tools.appimage;
in
  with lib; {
    options.desktop.tools.appimage.enable = mkEnableOption "Enable AppImage support";

    config = mkIf cfg.enable {
      programs.appimage = {
        enable = true;
        binfmt = true;
      };
    };
  }
