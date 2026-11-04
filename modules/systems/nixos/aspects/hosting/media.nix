{ den, ... }: {
  den.aspects.hosting.media = {
    includes = [
      den.aspects.hosting.microserver
    ];

    nixos =
      {
        lib,
        config,
        ...
      }:
      let
        cfg = config.hosting.microserver.media;
        inherit (cfg) root;
        inherit (cfg.jellyfin) renderDevice cardDevice;

        tz = lib.optionalAttrs (config.time.timeZone != null) {
          TZ = config.time.timeZone;
        };
        # LinuxServer images drop to this uid/gid inside the container.
        linuxserver = {
          PUID = "0";
          PGID = "0";
        };

        # One published media service: its state directory under /var/lib
        # and an oci-container exposed on the tailnet as
        # `<host>-<serviceName>`.
        mkService =
          name:
          {
            image,
            serviceName,
            containerPort,
            volumes,
            environment ? { },
            extra ? { },
          }:
          {
            tmpfiles = "d /var/lib/${name} 0755 root root -";
            container = lib.recursiveUpdate {
              inherit image volumes;
              environment = tz // environment;
              networks = [ "tailscale" ];
              labels = import ./_private/docktail-labels.nix {
                inherit (config.networking) hostName;
                inherit serviceName containerPort;
              };
            } extra;
          };

        services = lib.mapAttrs mkService {
          qbittorrent = {
            image = "linuxserver/qbittorrent:5.2.3";
            serviceName = "downloads";
            containerPort = 8080;
            environment = linuxserver // {
              WEBUI_PORT = "8080";
              TORRENTING_PORT = "6881";
            };
            volumes = [
              "/var/lib/qbittorrent:/config"
              "${root}/downloads:/downloads"
            ];
          };
          prowlarr = {
            image = "linuxserver/prowlarr:2.5.2";
            serviceName = "indexers";
            containerPort = 9696;
            environment = linuxserver;
            volumes = [
              "/var/lib/prowlarr:/config"
            ];
          };
          sonarr = {
            image = "linuxserver/sonarr:4.0.19";
            serviceName = "shows";
            containerPort = 8989;
            environment = linuxserver;
            volumes = [
              "/var/lib/sonarr:/config"
              "${root}/shows:/tv"
              "${root}/downloads:/downloads"
            ];
          };
          radarr = {
            image = "linuxserver/radarr:6.3.0";
            serviceName = "movies";
            containerPort = 7878;
            environment = linuxserver;
            volumes = [
              "/var/lib/radarr:/config"
              "${root}/movies:/movies"
              "${root}/downloads:/downloads"
            ];
          };
          lidarr = {
            image = "linuxserver/lidarr:3.1.0";
            serviceName = "music";
            containerPort = 8686;
            environment = linuxserver;
            volumes = [
              "/var/lib/lidarr:/config"
              "${root}/music:/music"
              "${root}/downloads:/downloads"
            ];
          };
          bookshelf = {
            image = "ghcr.io/pennydreadful/bookshelf:hardcover-v0.4.20.129";
            serviceName = "books";
            containerPort = 8787;
            environment = linuxserver;
            volumes = [
              "/var/lib/bookshelf:/config"
              "${root}/books:/books"
              "${root}/downloads:/downloads"
            ];
          };
          jellyfin = {
            image = "jellyfin/jellyfin:12";
            serviceName = "media";
            containerPort = 8096;
            # Preserve the LinuxServer volume layout while migrating to the
            # official image.
            environment = {
              JELLYFIN_CONFIG_DIR = "/config";
              JELLYFIN_DATA_DIR = "/config/data";
              JELLYFIN_CACHE_DIR = "/config/cache";
              JELLYFIN_LOG_DIR = "/config/log";
            };
            volumes = [
              "/var/lib/jellyfin:/config"
              "${root}/shows:/data/tvshows"
              "${root}/movies:/data/movies"
              "${root}/music:/data/music"
              "${root}/books:/data/books"
            ];
            # VAAPI/QSV hardware transcoding on the given GPU.
            extra.extraOptions = lib.optionals (renderDevice != null) [
              "--device=${renderDevice}:${renderDevice}"
              "--device=${cardDevice}:${cardDevice}"
            ];
          };
          seerr = {
            image = "seerr/seerr:v3.4.1";
            serviceName = "pvr";
            containerPort = 5055;
            volumes = [
              "/var/lib/seerr:/app/config:rw"
            ];
            extra.user = "0:0";
          };
        };
      in
      {
        options.hosting.microserver.media = {
          root = lib.mkOption {
            type = lib.types.str;
            default = "/mnt/local/media";
            description = "Directory holding downloads and the media libraries.";
          };

          jellyfin = {
            renderDevice = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/dev/dri/renderD128";
              description = ''
                Render node passed to Jellyfin for hardware transcoding. Set
                together with `cardDevice`; leave both null for software
                transcoding.
              '';
            };

            cardDevice = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/dev/dri/card1";
              description = ''
                Card node passed to Jellyfin for hardware transcoding. Set
                together with `renderDevice`; leave both null for software
                transcoding.
              '';
            };
          };
        };

        config = {
          assertions = [
            {
              assertion = (renderDevice == null) == (cardDevice == null);
              message = "hosting.microserver.media.jellyfin: set both renderDevice and cardDevice for hardware transcoding, or neither.";
            }
          ];

          systemd.tmpfiles.rules =
            map (dir: "d ${dir} 0755 root root -") [
              root
              "${root}/downloads"
              "${root}/movies"
              "${root}/shows"
              "${root}/music"
              "${root}/books"
            ]
            ++ lib.mapAttrsToList (_: s: s.tmpfiles) services;

          virtualisation.oci-containers.containers = lib.mapAttrs (_: s: s.container) services;
        };
      };
  };
}
