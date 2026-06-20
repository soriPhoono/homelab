{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.seerr;
in
  with lib; {
    options.hosting.media.seerr = {
      enable = mkEnableOption "Enable Seerr request manager for media hosting";

      port = mkOption {
        type = types.port;
        default = 5055;
        description = "Port for the Seerr web interface";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/seerr-team/seerr:latest";
        description = "Docker image for Seerr (Jellyseerr/Overseerr fork)";
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/seerr";
        description = "Host directory for Seerr configuration data";
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.seerr.uid;
        description = ''
          UID for file ownership on mounted volumes.
          The Seerr container runs as the "node" user (UID 1000 by default).
          Must match the container's runAsUser so it can write to the config directory.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.seerr.gid;
        description = ''
          GID for file ownership on mounted volumes.
          The Seerr container runs as the "node" group (GID 1000 by default).
        '';
      };

      domain = mkOption {
        type = types.str;
        default = "pvr.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"pvr.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Seerr web interface (used for Traefik routing).
        '';
      };

      logLevel = mkOption {
        type = types.enum [
          "debug"
          "info"
          "warn"
          "error"
        ];
        default = "info";
        description = "Log level for Seerr";
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
        default = ["--init"];
        description = ''
          Extra Docker options passed directly to the container runtime.

          The default includes '--init' because the Seerr image does not provide
          its own init process and relies on Docker's tini wrapper for proper
          signal handling and zombie reaping. If you override this list, you
          must include '--init' yourself or signal handling will break.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        users = {
          users.seerr = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.seerr.name;
          };
          groups = {
            seerr = {
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

        # Run Jellyseerr/Seerr as a Docker container via OCI module
        virtualisation.oci-containers.containers.seerr = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/app/config:rw"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              LOG_LEVEL = cfg.logLevel;
              PORT = toString cfg.port;
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.seerr.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.seerr.entrypoints" = "websecure";
              "traefik.http.routers.seerr.tls" = "true";
              "traefik.http.routers.seerr.tls.certresolver" = "le";
              "traefik.http.services.seerr.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
