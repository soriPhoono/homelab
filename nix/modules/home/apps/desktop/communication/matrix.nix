{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.communication.matrix;
in
  with lib; {
    options.apps.desktop.communication.matrix = {
      enable = mkEnableOption "Enable matrix client Element Desktop";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        element-desktop
      ];
    };
  }
