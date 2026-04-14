{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.asset-creation.krita;
in
  with lib; {
    options.userapps.content-creation.asset-creation.krita = {
      enable = mkEnableOption "Enable krita digital painting software";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        krita
      ];
    };
  }
