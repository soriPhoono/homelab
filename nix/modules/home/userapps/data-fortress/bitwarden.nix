{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.bitwarden;
in
  with lib; {
    options.userapps.data-fortress.bitwarden = {
      enable = mkEnableOption "Enable Bitwarden desktop client";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.bitwarden-desktop
      ];
    };
  }
