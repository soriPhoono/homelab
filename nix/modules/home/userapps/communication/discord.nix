{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.communication.discord;
in
  with lib; {
    options.userapps.communication.discord = {
      enable = mkEnableOption "Enable discord client";
    };

    config = mkIf cfg.enable {
      programs.vesktop.enable = true;
    };
  }
