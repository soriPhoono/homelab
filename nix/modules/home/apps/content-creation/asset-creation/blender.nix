{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.asset-creation.blender;
in
  with lib; {
    options.apps.content-creation.asset-creation.blender = {
      enable = mkEnableOption "Enable blender 3D modeling software";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        blender
      ];
    };
  }
