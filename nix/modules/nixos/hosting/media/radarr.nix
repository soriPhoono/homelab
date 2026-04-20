{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media.radarr;
in
  with lib; {
    options.hosting.media.radarr = {
      enable = mkEnableOption "Enable Radarr movie downloader";
    };

    config = mkIf cfg.enable {
      services.radarr.enable = true;
    };
  }
