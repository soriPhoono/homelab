{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.communication.matrix;
in
  with lib; {
    options.userapps.desktop.communication.matrix = {
      enable = mkEnableOption "Enable matrix client Element Desktop";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        element-desktop
      ];
    };
  }
