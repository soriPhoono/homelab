{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.communication.signal;
in
  with lib; {
    options.userapps.desktop.communication.signal = {
      enable = mkEnableOption "Enable signal desktop for private texting features";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        signal-desktop
      ];
    };
  }
