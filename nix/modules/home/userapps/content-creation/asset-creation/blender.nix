{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.asset-creation.blender;
in
  with lib; {
    options.userapps.content-creation.asset-creation.blender = {
      enable = mkEnableOption "Enable blender 3D modeling software";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        blender
      ];
    };
  }
