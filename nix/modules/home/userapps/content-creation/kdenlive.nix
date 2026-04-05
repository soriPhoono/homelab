{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.kdenlive;
in
  with lib; {
    options.userapps.content-creation.kdenlive = {
      enable = mkEnableOption "Davinci Resolve";
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.kdePackages.kdenlive];
    };
  }
