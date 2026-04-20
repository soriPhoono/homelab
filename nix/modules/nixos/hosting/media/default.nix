# TODO: Write configuration to define urlBase for all services
# TODO: Write configuration to create storage directory tree under /mnt/local
# TODO: Add Prowlarr
# TODO: Add qbittorrent
{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media;
in
  with lib; {
    imports = [
      ./jellyfin.nix
      ./seerr.nix
      ./sonarr.nix
      ./radarr.nix
    ];

    options.hosting.media = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable media hosting services";
      };
    };

    config = mkIf cfg.enable {
      # Jellyfin
      hosting.media = {
        jellyfin = {
          enable = true;
          acceleration.enable = true;
        };
        seerr.enable = true;
        sonarr.enable = true;
        radarr.enable = true;
      };

      # Caddy
      hosting.proxy = {
        enable = true;
        services = {
          media = {
            proxyPort = config.services.seerr.port;
            extraPaths = {
              "/movies" = 7878;
              "/shows" = 8989;
              "/watch" = 8096;
            };
          };
        };
      };
    };
  }
