{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.editors.kdenlive;
in
  with lib; {
    options.userapps.content-creation.editors.kdenlive = {
      enable = mkEnableOption "Kdenlive";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        kdePackages.kdenlive
      ];
    };
  }
