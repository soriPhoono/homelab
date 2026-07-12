{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.communication.telegram;
in
  with lib; {
    options.apps.desktop.communication.telegram = {
      enable = mkEnableOption "Enable telegram desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        telegram-desktop
      ];
    };
  }
