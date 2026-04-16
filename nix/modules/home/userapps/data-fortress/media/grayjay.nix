{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.media.grayjay;
in
  with lib; {
    options.userapps.data-fortress.media.grayjay = {
      enable = mkEnableOption "Enable Grayjay media alternative UI";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        grayjay
      ];
    };
  }
