{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.content-creation.editors.kdenlive;
in
  with lib; {
    options.apps.content-creation.editors.kdenlive = {
      enable = mkEnableOption "Kdenlive";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        kdePackages.kdenlive
      ];
    };
  }
