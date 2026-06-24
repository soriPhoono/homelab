{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.hermes;

  inherit
    (lib)
    mkIf
    mkEnableOption
    mkOption
    mkDefault
    mkMerge
    types
    optional
    flatten
    mapAttrs'
    mapAttrsToList
    nameValuePair
    filterAttrs
    ;

  baseDomain =
    if config.hosting.proxy.dns.localSubdomain != ""
    then "${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}"
    else config.hosting.proxy.dns.baseDomain;

  # Create container definition for a single user
  mkHermesContainer = username: uc: let
    uid =
      if uc.uid != null
      then uc.uid
      else config.users.users.${username}.uid or 1000;
    gid =
      if uc.gid != null
      then uc.gid
      else config.users.groups.${username}.gid or 1000;
  in {
    inherit (cfg) image;
    autoStart = true;
    networks = ["proxy"];
    volumes = [
      "/home/${username}/.hermes:/opt/data:rw"
    ];
    environment = {
      HERMES_UID = toString uid;
      HERMES_GID = toString gid;
      HERMES_DASHBOARD = "1";
      HERMES_DASHBOARD_PORT = toString uc.dashboardPort;
      API_SERVER_ENABLED = "true";
      API_SERVER_HOST = "0.0.0.0";
      API_SERVER_PORT = toString uc.apiPort;
      API_SERVER_MODEL_NAME = "${username}-default";
    };
    cmd = ["gateway" "run"];
    labels =
      {
        "traefik.enable" = "true";

        # Dashboard route
        "traefik.http.routers.hermes-${username}.rule" = "Host(`${username}.${cfg.agentSubdomain}.${baseDomain}`)";
        "traefik.http.routers.hermes-${username}.entrypoints" = "websecure";
        "traefik.http.routers.hermes-${username}.tls" = "true";
        "traefik.http.routers.hermes-${username}.tls.certresolver" = "le";
        "traefik.http.services.hermes-${username}.loadbalancer.server.port" = toString uc.dashboardPort;

        # API route
        "traefik.http.routers.hermes-api-${username}.rule" = "Host(`api-${username}.${cfg.agentSubdomain}.${baseDomain}`)";
        "traefik.http.routers.hermes-api-${username}.entrypoints" = "websecure";
        "traefik.http.routers.hermes-api-${username}.tls" = "true";
        "traefik.http.routers.hermes-api-${username}.tls.certresolver" = "le";
        "traefik.http.services.hermes-api-${username}.loadbalancer.server.port" = toString uc.apiPort;
      }
      // uc.extraLabels;
    extraOptions =
      uc.extraOptions
      ++ optional (uc.cpuLimit != null) "--cpus=${uc.cpuLimit}"
      ++ optional (uc.memoryLimit != null) "--memory=${uc.memoryLimit}";
  };
in {
  options.hosting.hermes = {
    enable = mkEnableOption "Hermes Agent Docker containers — one per configured user";

    image = mkOption {
      type = types.str;
      default = "nousresearch/hermes-agent:v2026.6.19";
      description = "Pinned Docker image for hermes-agent. Versioned tags preferred for reproducibility.";
    };

    agentSubdomain = mkOption {
      type = types.str;
      default = "agent";
      description = "Subdomain prefix for hermes agent routes (dashboard + API).";
    };

    users = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "hermes-agent container for this user";

          uid = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Host UID for container permission mapping. Auto-derived from system user if not set.";
          };

          gid = mkOption {
            type = types.nullOr types.int;
            default = null;
            description = "Host GID for container permission mapping. Auto-derived from system user if not set.";
          };

          cpuLimit = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "2.0";
            description = "Docker CPU quota (e.g. '2.0' for 2 cores).";
          };

          memoryLimit = mkOption {
            type = types.nullOr types.str;
            default = null;
            example = "4g";
            description = "Docker memory limit (e.g. '4g').";
          };

          dashboardPort = mkOption {
            type = types.int;
            default = 9119;
            description = "Internal container port for the hermes web dashboard.";
          };

          apiPort = mkOption {
            type = types.int;
            default = 8642;
            description = "Internal container port for the OpenAI-compatible API server.";
          };

          extraLabels = mkOption {
            type = types.attrsOf types.str;
            default = {};
            description = "Additional Traefik labels merged onto the container.";
          };

          extraOptions = mkOption {
            type = types.listOf types.str;
            default = [];
            description = "Additional Docker options passed to the container.";
          };
        };
      });
      default = {};
      description = "Per-user hermes-agent container configuration.";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      # Ensure Docker platform is enabled
      hosting.platforms.docker.enable = mkDefault true;

      # Create base ~/.hermes per user via tmpfiles
      systemd.tmpfiles.rules = flatten (
        mapAttrsToList (
          username: uc:
            optional uc.enable "d /home/${username}/.hermes 0700 ${username} users -"
        )
        cfg.users
      );
    }

    # Create Docker containers for each enabled user
    {
      virtualisation.oci-containers.containers =
        mapAttrs' (
          username: uc:
            nameValuePair "hermes-${username}" (mkHermesContainer username uc)
        )
        (filterAttrs (_: uc: uc.enable) cfg.users);
    }
  ]);
}
