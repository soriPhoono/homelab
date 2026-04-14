{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.asset-creation.inkscape;
in
  with lib; {
    options.userapps.content-creation.asset-creation.inkscape = {
      enable = mkEnableOption "Enable inkscape vector graphics editor";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        inkscape
      ];
    };
  }
