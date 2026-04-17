{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.virtualization.bottles;
in
  with lib; {
    options.userapps.desktop.virtualization.bottles = {
      enable = mkEnableOption "Enable bottles for running Windows applications via WINE";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bottles
      ];
    };
  }
