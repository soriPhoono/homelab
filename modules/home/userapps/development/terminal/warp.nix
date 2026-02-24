{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.development.terminal.warp;
in
  with lib; {
    options.userapps.development.terminal.warp = {
      enable = mkEnableOption "Enable warp terminal";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        warp-terminal
      ];
    };
  }
