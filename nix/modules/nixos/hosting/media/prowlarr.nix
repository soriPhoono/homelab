{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.prowlarr;
in
  with lib; {
    options.hosting.media.prowlarr = {
      enable = mkEnableOption "Enable Prowlarr indexer manager for Trackers";
    };

    config = mkIf cfg.enable {
      services.prowlarr.enable = true;

      systemd.services.prowlarr.serviceConfig = {
        ProtectSystem = lib.mkForce "strict";
        ProtectHome = lib.mkForce true;
        PrivateDevices = true;
      };
    };
  }
