{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.virtualization.bottles;
in
  with lib; {
    options.apps.desktop.virtualization.bottles = {
      enable = mkEnableOption "Enable bottles for running Windows applications via WINE";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        bottles
      ];
    };
  }
