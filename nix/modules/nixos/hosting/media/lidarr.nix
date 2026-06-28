{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.lidarr;
in
  with lib; {
    options.hosting.media.lidarr = {
      enable = mkEnableOption "Enable Lidarr PVR for music Usenet and BitTorrent users";

      port = mkOption {
        type = types.port;
        default = 8686;
        description = "Port for the Lidarr web interface";
      };

      image = mkOption {
        type = types.str;
        default = "linuxserver/lidarr:latest";
        description = ''
          Docker image for Lidarr.
          Uses the linuxserver image by default (the Lidarr team does not publish an official image).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/lidarr";
        description = "Host directory for Lidarr configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "music.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"music.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Lidarr web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.lidarr.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.lidarr.gid;
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
          users.lidarr = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.lidarr.name;
          };
          groups = {
            lidarr = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.lidarr.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.lidarr = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
              "/mnt/local/media/music:/music"
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
              "traefik.http.routers.lidarr.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.lidarr.entrypoints" = "websecure";
              "traefik.http.routers.lidarr.tls" = "true";
              "traefik.http.routers.lidarr.tls.certresolver" = "le";
              "traefik.http.services.lidarr.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
