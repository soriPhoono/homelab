{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.gimp;
in
  with lib; {
    options.userapps.content-creation.gimp.enable = mkEnableOption "Enable GIMP image editor";
    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        gimp
      ];
    };
  }
