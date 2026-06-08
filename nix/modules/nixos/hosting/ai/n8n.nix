{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.ai.n8n;
in
  with lib; {
    options.hosting.ai.n8n = {
      enable = mkEnableOption "n8n workflow automation with AI/LLM capabilities";

      port = mkOption {
        type = types.port;
        default = 5678;
        description = "Port for the n8n web interface";
      };

      image = mkOption {
        type = types.str;
        default = "docker.n8n.io/n8nio/n8n";
        description = ''
          Docker image for n8n.
          Uses the official image from Docker Hub.
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/n8n";
        description = "Host directory for n8n configuration and data";
      };

      domain = mkOption {
        type = types.str;
        default = "ai.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"ai.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the n8n web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.ai.n8n.uid;
        description = "UID for the n8n container process";
      };

      userGid = mkOption {
        type = types.int;
        default = uids.ai.n8n.gid;
        description = "GID for the n8n container process";
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

      environment = mkOption {
        type = types.attrsOf types.str;
        default = {};
        example = {
          N8N_ENCRYPTION_KEY = "your-encryption-key";
          N8N_USER_MANAGEMENT_JWT_SECRET = "your-jwt-secret";
        };
        description = ''
          Additional environment variables passed to the n8n container.
          Useful for setting secrets like N8N_ENCRYPTION_KEY and
          N8N_USER_MANAGEMENT_JWT_SECRET.
        '';
      };
    };

    config = mkIf cfg.enable {
      users = {
        users.n8n = {
          isSystemUser = true;
          uid = mkDefault cfg.userUid;
          group = config.users.groups.n8n.name;
        };
        groups.n8n = {
          gid = mkDefault cfg.userGid;
        };
      };

      # Auto-enable the Docker container hosting platform
      hosting.platforms.docker.enable = mkDefault true;

      # Ensure config directory exists
      systemd.tmpfiles.rules = [
        "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        "d ${cfg.configDir}/data 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
      ];

      virtualisation.oci-containers.containers.n8n = {
        inherit (cfg) image;
        autoStart = true;
        networks = ["proxy"];

        volumes =
          [
            "${cfg.configDir}/data:/home/node/.n8n"
          ]
          ++ cfg.extraVolumes;

        environment =
          {
            TZ = config.time.timeZone;
            GENERIC_TIMEZONE = config.time.timeZone;
            N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
            N8N_PORT = toString cfg.port;
            N8N_PROTOCOL = "https";
            N8N_HOST = cfg.domain;
            WEBHOOK_URL = "https://${cfg.domain}/";
            NODE_ENV = "production";
          }
          // cfg.environment;

        # Traefik auto-discovery labels
        labels =
          {
            "traefik.enable" = "true";
            "traefik.http.routers.n8n.rule" = "Host(`${cfg.domain}`)";
            "traefik.http.routers.n8n.entrypoints" = "websecure";
            "traefik.http.routers.n8n.tls" = "true";
            "traefik.http.routers.n8n.tls.certresolver" = "le";
            "traefik.http.services.n8n.loadbalancer.server.port" = toString cfg.port;
          }
          // cfg.extraLabels;

        inherit (cfg) extraOptions;
      };
    };
  }
