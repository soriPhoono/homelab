{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.data-fortress.cloud.nextcloud;
in
  with lib; {
    options.userapps.data-fortress.cloud.nextcloud = {
      enable = mkEnableOption "Enable Nextcloud client";
    };

    config = mkIf cfg.enable {
      home.packages = [
        pkgs.nextcloud-client
      ];
    };
  }
