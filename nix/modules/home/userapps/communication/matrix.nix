{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.communication.matrix;
in
  with lib; {
    options.userapps.communication.matrix = {
      enable = mkEnableOption "Enable matrix client Element Desktop";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        element-desktop
      ];
    };
  }
