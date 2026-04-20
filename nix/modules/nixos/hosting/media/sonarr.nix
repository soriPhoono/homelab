{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.sonarr;
in
  with lib; {
    options.hosting.media.sonarr = {
      enable = mkEnableOption "Enable Sonarr PVR for Usenet and BitTorrent users";
    };

    config = mkIf cfg.enable {
      services.sonarr.enable = true;
    };
  }
