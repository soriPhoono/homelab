{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.communication.telegram;
in
  with lib; {
    options.userapps.communication.telegram = {
      enable = mkEnableOption "Enable telegram desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        telegram-desktop
      ];
    };
  }
