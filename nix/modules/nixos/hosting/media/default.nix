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
            name = "qBittorrent";
            description = ''
              Qbittorrent is a powerful and user-friendly torrent client that allows you to easily manage your torrent downloads. With its intuitive interface and robust features, you can effortlessly organize, prioritize, and monitor your torrent downloads from anywhere. Whether you're a seasoned torrent user or new to the world of torrenting, qbittorrent provides a seamless experience for all your downloading needs.
            '';
            proxyPort = config.services.qbittorrent.webuiPort;
            extraPaths = {
              "/indexers" = {
                name = "Prowlarr";
                description = ''
                  Prowlarr is a powerful and user-friendly indexer manager that allows you to easily manage and organize your torrent indexers. With its intuitive interface and robust features, you can effortlessly add, remove, and monitor your torrent indexers from anywhere. Whether you're a seasoned torrent user or new to the world of torrenting, Prowlarr provides a seamless experience for all your indexer management needs.
                '';
                proxyPort = config.services.prowlarr.settings.server.port;
              };
            };
          };
          media = {
            name = "Seer";
            description = ''
              Seer is a media request management system that allows you to easily manage and organize your media requests. With its intuitive interface and robust features, you can effortlessly add, remove, and monitor your media requests from anywhere. Whether you're a seasoned media enthusiast or new to the world of media management, Seer provides a seamless experience for all your media request management needs.
            '';
            proxyPort = config.services.seerr.port;
            extraPaths = {
              "/movies" = {
                name = "Radarr";
                description = ''
                  Radarr is a powerful and user-friendly movie collection manager that allows you to easily manage and organize your movie collection. With its intuitive interface and robust features, you can effortlessly add, remove, and monitor your movie collection from anywhere. Whether you're a seasoned movie enthusiast or new to the world of movie management, Radarr provides a seamless experience for all your movie collection management needs.
                '';
                proxyPort = config.services.radarr.settings.server.port;
              };
              "/shows" = {
                name = "Sonarr";
                description = ''
                  Sonarr is a powerful and user-friendly TV show collection manager that allows you to easily manage and organize your TV show collection. With its intuitive interface and robust features, you can effortlessly add, remove, and monitor your TV show collection from anywhere. Whether you're a seasoned TV show enthusiast or new to the world of TV show management, Sonarr provides a seamless experience for all your TV show collection management needs.
                '';
                proxyPort = config.services.sonarr.settings.server.port;
              };
              "/watch" = {
                name = "Jellyfin";
                description = ''
                  Jellyfin is a free software media server that puts you in control of your media. It allows you to organize, manage, and stream your media collection to various devices, both locally and remotely. With features like live TV support, DVR capabilities, and a user-friendly interface, Jellyfin is a popular choice for media enthusiasts looking for an open-source alternative to commercial media servers.
                '';
                proxyPort = 8096;
              };
            };
          };
        };
      };
    };
  }
