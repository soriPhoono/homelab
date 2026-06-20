{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.prowlarr;
in
  with lib; {
    options.hosting.media.prowlarr = {
      enable = mkEnableOption "Enable Prowlarr indexer manager for trackers";

      port = mkOption {
        type = types.port;
        default = 9696;
        description = "Port for the Prowlarr web interface";
      };

      image = mkOption {
        type = types.str;
        default = "lscr.io/linuxserver/prowlarr:latest";
        description = ''
          Docker image for Prowlarr.
          Uses the linuxserver image by default (supports PUID/PGID).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/prowlarr";
        description = "Host directory for Prowlarr configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "indexers.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"indexers.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Prowlarr web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.prowlarr.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.prowlarr.gid;
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
          users.prowlarr = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.prowlarr.name;
          };
          groups = {
            prowlarr = {
              gid = mkDefault cfg.userGid;
            };
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.prowlarr = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              PUID = toString cfg.userUid;
              PGID = toString cfg.userGid;
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.prowlarr.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.prowlarr.entrypoints" = "websecure";
              "traefik.http.routers.prowlarr.tls" = "true";
              "traefik.http.routers.prowlarr.tls.certresolver" = "le";
              "traefik.http.services.prowlarr.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
