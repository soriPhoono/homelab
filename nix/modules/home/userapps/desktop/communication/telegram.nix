{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.communication.telegram;
in
  with lib; {
    options.userapps.desktop.communication.telegram = {
      enable = mkEnableOption "Enable telegram desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        telegram-desktop
      ];
    };
  }
