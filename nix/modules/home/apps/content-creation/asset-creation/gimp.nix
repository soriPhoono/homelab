{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.asset-creation.gimp;
in
  with lib; {
    options.apps.content-creation.asset-creation.gimp = {
      enable = mkEnableOption "Enable GIMP image editor";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        gimp
      ];
    };
  }
