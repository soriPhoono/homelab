{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.communication.signal;
in
  with lib; {
    options.userapps.communication.signal = {
      enable = mkEnableOption "Enable signal desktop for private texting features";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        signal-desktop
      ];
    };
  }
