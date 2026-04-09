{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.communication.discord;
in
  with lib; {
    options.userapps.desktop.communication.discord = {
      enable = mkEnableOption "Enable discord client";
    };

    config = mkIf cfg.enable {
      programs.vesktop.enable = true;
    };
  }
