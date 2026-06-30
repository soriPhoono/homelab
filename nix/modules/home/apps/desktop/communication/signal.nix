{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.apps.desktop.communication.signal;
in
  with lib; {
    options.apps.desktop.communication.signal = {
      enable = mkEnableOption "Enable signal desktop for private texting features";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        signal-desktop
      ];
    };
  }
