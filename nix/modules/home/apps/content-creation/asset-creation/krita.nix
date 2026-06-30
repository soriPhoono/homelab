{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.asset-creation.krita;
in
  with lib; {
    options.apps.content-creation.asset-creation.krita = {
      enable = mkEnableOption "Enable krita digital painting software";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        krita
      ];
    };
  }
