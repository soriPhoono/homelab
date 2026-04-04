{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.grayjay;
in
  with lib; {
    options.userapps.data-fortress.grayjay = {
      enable = mkEnableOption "Enable Grayjay media alternative UI";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        grayjay
      ];
    };
  }
