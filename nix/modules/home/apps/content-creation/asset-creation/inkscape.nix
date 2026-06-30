{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.asset-creation.inkscape;
in
  with lib; {
    options.apps.content-creation.asset-creation.inkscape = {
      enable = mkEnableOption "Enable inkscape vector graphics editor";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        inkscape
      ];
    };
  }
