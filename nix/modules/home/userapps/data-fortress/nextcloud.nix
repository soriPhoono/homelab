{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.nextcloud;
in
  with lib; {
    options.userapps.data-fortress.nextcloud = {
      enable = mkEnableOption "Enable Nextcloud client";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.nextcloud-client
      ];
    };
  }
