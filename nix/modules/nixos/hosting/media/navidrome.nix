{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.navidrome;
in
  with lib; {
    options.hosting.media.navidrome = {
      enable = mkEnableOption "Enable Navidrome music streaming server";

      port = mkOption {
        type = types.port;
        default = 4533;
        description = "Port for the Navidrome web interface";
      };

      image = mkOption {
        type = types.str;
        default = "deluan/navidrome:latest";
        description = ''
          Docker image for Navidrome.
          Uses the official image by default.
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/navidrome";
        description = "Host directory for Navidrome configuration and database";
      };

      musicDir = mkOption {
        type = types.str;
        default = "/mnt/local/media/music";
        description = "Host directory for music files";
      };

      domain = mkOption {
        type = types.str;
        default = "music.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"music.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Navidrome web interface (used for Traefik routing
          and ND_BASEURL).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.navidrome.uid;
        description = ''
          UID for the navidrome process inside the container.
          Should match the owner of your music files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.navidrome.gid;
        description = ''
          GID for the navidrome process inside the container.
          Should match the group of your music files on the host.
        '';
      };

      extraVolumes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional volume mounts for the container.
          Each entry should be in Docker volume format: "/host/path:/container/path[:mode]"
          Example: "/extra/media:/data/extra:ro"
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
          users.navidrome = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.navidrome.name;
          };
          groups = {
            navidrome = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.navidrome.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.navidrome = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          user = "${toString cfg.userUid}:${toString cfg.userGid}";

          volumes =
            [
              "${cfg.configDir}:/data"
              "${cfg.musicDir}:/music:ro"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              ND_BASEURL = "https://${cfg.domain}";
              ND_SCANSCHEDULE = "every 1h";
              ND_SESSIONTIMEOUT = "24h";
              ND_LOGLEVEL = "info";
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.navidrome.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.navidrome.entrypoints" = "websecure";
              "traefik.http.routers.navidrome.tls" = "true";
              "traefik.http.routers.navidrome.tls.certresolver" = "le";
              "traefik.http.services.navidrome.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
