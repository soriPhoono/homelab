{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.media;
in
  with lib; {
    imports = [
      ./seerr.nix
      ./sonarr.nix
      ./radarr.nix
      ./prowlarr.nix
      ./flaresolverr.nix
      ./qbittorrent.nix
      ./jellyfin.nix
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
      hosting = {
        media = {
          jellyfin = {
            enable = true;
            acceleration.enable = true;
          };
          seerr.enable = true;
          sonarr.enable = true;
          radarr.enable = true;
          prowlarr.enable = true;
          flaresolverr.enable = true;
          qbittorrent.enable = true;
        };
      };

      systemd.tmpfiles.rules = [
        "d /mnt/local 0775 - - -"
        "d /mnt/local/media 0775 - ${config.users.groups.media.name} -"
        "d /mnt/local/media/movies 0775 ${config.services.radarr.user} ${config.users.groups.media.name} -"
        "d /mnt/local/media/shows 0775 ${config.services.sonarr.user} ${config.users.groups.media.name} -"
        "d /mnt/local/media/downloads 0775 ${config.services.qbittorrent.user} ${config.users.groups.media.name} -"
      ];

      # Caddy
      hosting.proxy = {
        enable = true;
        services = {
          downloads = {
            proxyPort = config.services.qbittorrent.webuiPort;
            extraPaths = {
              "/indexers" = {
                proxyPort = config.services.prowlarr.settings.server.port;
              };
            };
          };
          media = {
            proxyPort = config.services.seerr.port;
            extraPaths = {
              "/movies" = {
                proxyPort = config.services.radarr.settings.server.port;
              };
              "/shows" = {
                proxyPort = config.services.sonarr.settings.server.port;
              };
              "/watch" = {
                proxyPort = 8096;
              };
            };
          };
        };
      };
    };
  }
