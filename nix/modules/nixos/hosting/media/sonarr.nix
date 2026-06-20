{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.sonarr;
in
  with lib; {
    options.hosting.media.sonarr = {
      enable = mkEnableOption "Enable Sonarr PVR for Usenet and BitTorrent users";

      port = mkOption {
        type = types.port;
        default = 8989;
        description = "Port for the Sonarr web interface";
      };

      image = mkOption {
        type = types.str;
        default = "linuxserver/sonarr:latest";
        description = ''
          Docker image for Sonarr.
          Uses the linuxserver image by default (the Sonarr team does not publish an official image).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/sonarr";
        description = "Host directory for Sonarr configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "shows.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"shows.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Sonarr web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.sonarr.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.sonarr.gid;
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
          users.sonarr = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.sonarr.name;
          };
          groups = {
            sonarr = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.sonarr.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.sonarr = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
              "/mnt/local/media/shows:/tv"
              "/mnt/local/media/downloads:/downloads"
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
              "traefik.http.routers.sonarr.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.sonarr.entrypoints" = "websecure";
              "traefik.http.routers.sonarr.tls" = "true";
              "traefik.http.routers.sonarr.tls.certresolver" = "le";
              "traefik.http.services.sonarr.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
