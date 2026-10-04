/**
  Microservers: containers published to the tailnet through docktail.

  The base aspect runs the docktail proxy and its Tailscale sidecar; each
  sub-aspect adds a group of services that publish through it.
*/
{ den, ... }:
{
  den.aspects.hosting.microserver = {
    includes = [
      den.aspects.hosting.docker
    ];

    nixos =
      { config, ... }:
      {
        sops = {
          secrets = {
            "microserver/tailscale-sidecar-authkey" = { };
            "microserver/tailscale-oauth-client-id" = { };
            "microserver/tailscale-oauth-client-secret" = { };
          };
          templates = {
            "docktail/tailscale-oauth".content = ''
              TAILSCALE_OAUTH_CLIENT_ID=${config.sops.placeholder."microserver/tailscale-oauth-client-id"}
              TAILSCALE_OAUTH_CLIENT_SECRET=${config.sops.placeholder."microserver/tailscale-oauth-client-secret"}
            '';
            "docktail/tailscale-sidecar-authkey".content = ''
              TS_AUTHKEY=${config.sops.placeholder."microserver/tailscale-sidecar-authkey"}
            '';
          };
        };

        virtualisation.oci-containers.containers = {
          tailscale-sidecar = {
            image = "tailscale/tailscale:v1.102.3";
            capabilities.NET_ADMIN = true;
            environment = {
              TS_HOSTNAME = "${config.networking.hostName}-microserver";
              TS_SOCKET = "/var/run/tailscale/tailscaled.sock";
              TS_STATE_DIR = "/var/lib/tailscale";
              TS_EXTRA_ARGS = "--advertise-tags=tag:microserver";
              TS_USERSPACE = "false";
            };
            environmentFiles = [
              config.sops.templates."docktail/tailscale-sidecar-authkey".path
            ];
            volumes = [
              "tailscale-state:/var/lib/tailscale"
              "tailscale-socket:/var/run/tailscale"
            ];
            networks = [
              "tailscale"
            ];
            extraOptions = [
              "--device=/dev/net/tun:/dev/net/tun"
            ];
            ports = [
              "41642:41641/udp"
            ];
          };

          docktail = {
            image = "ghcr.io/marvinvr/docktail:1.3.0";
            dependsOn = [
              "tailscale-sidecar"
            ];
            extraOptions = [
              "--network=container:tailscale-sidecar"
            ];
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock:ro"
              "tailscale-socket:/var/run/tailscale"
            ];
            environment = {
              DEFAULT_SERVICE_TAGS = "tag:microservice";
            };
            environmentFiles = [
              config.sops.templates."docktail/tailscale-oauth".path
            ];
          };
        };
      };

    media = {
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
  };
}
