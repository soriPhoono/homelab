{
  lib,
  config,
  ...
}: let
  cfg = config.apps.desktop.communication.discord;
in
  with lib; {
    options.apps.desktop.communication.discord = {
      enable = mkEnableOption "Enable discord client";
    };

    config = mkIf cfg.enable {
      programs.discord.enable = true;
    };
  }
