{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.content-creation.davinci-resolve;
in
  with lib; {
    options.userapps.content-creation.davinci-resolve = {
      enable = mkEnableOption "Davinci Resolve";
    };

    config = mkIf cfg.enable {
      home.packages = [pkgs.kdePackages.kdenlive];
    };
  }
