{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.radarr;
in
  with lib; {
    options.hosting.media.radarr = {
      enable = mkEnableOption "Enable Radarr movie downloader";

      port = mkOption {
        type = types.port;
        default = 7878;
        description = "Port for the Radarr web interface";
      };

      image = mkOption {
        type = types.str;
        default = "linuxserver/radarr:latest";
        description = ''
          Docker image for Radarr.
          Uses the linuxserver image by default (the Radarr team does not publish an official image).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/radarr";
        description = "Host directory for Radarr configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "movies.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"movies.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Radarr web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.radarr.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.radarr.gid;
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

    config = mkIf cfg.enable {
      users = {
        users.radarr = {
          isSystemUser = true;
          uid = mkDefault cfg.userUid;
          group = config.users.groups.radarr.name;
        };
        groups = {
          radarr = {
            gid = mkDefault cfg.userGid;
          };
          media.members = [
            config.users.users.radarr.name
          ];
        };
      };

      # Auto-enable the Docker container hosting platform
      hosting.platforms.docker.enable = mkDefault true;

      # Ensure config directory exists
      systemd.tmpfiles.rules = [
        "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
      ];

      virtualisation.oci-containers.containers.radarr = {
        inherit (cfg) image;
        autoStart = true;
        networks = ["proxy"];

        volumes =
          [
            "${cfg.configDir}:/config"
            "/mnt/local/media/movies:/movies"
            "/mnt/local/media/downloads:/downloads"
          ]
          ++ cfg.extraVolumes;

        environment = {
          TZ = config.time.timeZone;
          PUID = toString cfg.userUid;
          PGID = toString cfg.userGid;
        };

        # Traefik auto-discovery labels
        labels =
          {
            "traefik.enable" = "true";
            "traefik.http.routers.radarr.rule" = "Host(`${cfg.domain}`)";
            "traefik.http.routers.radarr.entrypoints" = "websecure";
            "traefik.http.routers.radarr.tls" = "true";
            "traefik.http.routers.radarr.tls.certresolver" = "le";
            "traefik.http.services.radarr.loadbalancer.server.port" = toString cfg.port;
          }
          // cfg.extraLabels;

        inherit (cfg) extraOptions;
      };
    };
  }
