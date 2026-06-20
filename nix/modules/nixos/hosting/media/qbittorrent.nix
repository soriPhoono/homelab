{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.qbittorrent;
in
  with lib; {
    options.hosting.media.qbittorrent = {
      enable = mkEnableOption "Enable qBittorrent BitTorrent client";

      port = mkOption {
        type = types.port;
        default = 8080;
        description = "Port for the qBittorrent web interface";
      };

      torrentingPort = mkOption {
        type = types.port;
        default = 6881;
        description = "TCP/UDP port for BitTorrent connections";
      };

      image = mkOption {
        type = types.str;
        default = "lscr.io/linuxserver/qbittorrent:latest";
        description = ''
          Docker image for qBittorrent.
          Uses the linuxserver image by default (supports PUID/PGID).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/qbittorrent";
        description = "Host directory for qBittorrent configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "downloads.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"downloads.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the qBittorrent web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.qbittorrent.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.qbittorrent.gid;
        description = ''
          GID for file ownership on mounted volumes.
          Should match the group of your media files on the host.
        '';
      };

      extraVolumes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional volume mounts for the container.
          Each entry should be in Docker volume format: "/host/path:/container/path[:mode]"
        '';
      };

      extraLabels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional Docker labels for the container (e.g., Traefik middleware).";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra Docker options passed directly to the container runtime.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        users = {
          users.qbittorrent = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.qbittorrent.name;
          };
          groups = {
            qbittorrent = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.qbittorrent.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.qbittorrent = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
              "/mnt/local/media/downloads:/downloads"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              PUID = toString cfg.userUid;
              PGID = toString cfg.userGid;
              WEBUI_PORT = toString cfg.port;
              TORRENTING_PORT = toString cfg.torrentingPort;
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.qbittorrent.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
              "traefik.http.routers.qbittorrent.tls" = "true";
              "traefik.http.routers.qbittorrent.tls.certresolver" = "le";
              "traefik.http.services.qbittorrent.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
