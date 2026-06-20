{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.jellyfin;
in
  with lib; {
    options.hosting.media.jellyfin = {
      enable = mkEnableOption "Enable Jellyfin media server for edge device media archiving";
      acceleration.enable = mkEnableOption "Enable hardware acceleration (VAAPI) on the integrated GPU";

      image = mkOption {
        type = with types; str;
        default = "jellyfin/jellyfin:latest";
        description = ''
          Docker image for Jellyfin.
          Uses the official image by default.
        '';
      };

      configDir = mkOption {
        type = with types; str;
        default = "/var/lib/jellyfin";
        description = ''
          Host directory for Jellyfin configuration.
        '';
      };

      cacheDir = mkOption {
        type = with types; str;
        default = "/var/cache/jellyfin";
        description = ''
          Host directory for Jellyfin transcode cache.
          The official image separates cache from config ("/cache" inside the container).
        '';
      };

      domain = mkOption {
        type = types.str;
        default = "media.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"media.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Jellyfin web interface (used for Traefik routing
          and JELLYFIN_PublishedServerUrl).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.jellyfin.uid;
        description = ''
          UID for the jellyfin process inside the container. Should match the
          owner of your media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.jellyfin.gid;
        description = ''
          GID for the jellyfin process inside the container. Should match the
          group of your media files on the host.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 8096;
        description = ''
          Internal container port for the Jellyfin web interface.
          The Traefik label already targets this port; you only need to
          expose it to the host if you want direct LAN access without
          going through the reverse proxy.
        '';
      };

      extraVolumes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional volume mounts for the container.
          Each entry should be in Docker volume format: "/host/path:/container/path[:mode]"
          Example: "/extra/media:/data/music:ro"
        '';
      };

      extraLabels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = ''
          Additional Docker labels for the container.
          Useful for adding Traefik middleware or custom metadata.
        '';
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Extra Docker options passed directly to the container runtime.
          Example: ["--device=/dev/dri:/dev/dri"] for hardware acceleration.
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        users = {
          users.jellyfin = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.jellyfin.name;
          };
          groups = {
            jellyfin = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.jellyfin.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
          "d ${cfg.cacheDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.jellyfin = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
              "${cfg.cacheDir}:/cache"
              "/mnt/local/media/shows:/data/tvshows"
              "/mnt/local/media/movies:/data/movies"
            ]
            # Mount init script for subpath routing (sets Jellyfin's BaseUrl)
            ++ cfg.extraVolumes;

          environment = mkMerge [
            {
              JELLYFIN_PublishedServerUrl = "https://${cfg.domain}";
            }
            (mkIf (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            })
          ];

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.jellyfin.entrypoints" = "websecure";
              "traefik.http.routers.jellyfin.tls" = "true";
              "traefik.http.routers.jellyfin.tls.certresolver" = "le";
              "traefik.http.services.jellyfin.loadbalancer.server.port" = toString cfg.port;
              "traefik.http.routers.jellyfin.rule" = "Host(`${cfg.domain}`)";
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }

      # ── Hardware acceleration (VAAPI/QSV) ────────────────
      (mkIf cfg.acceleration.enable {
        # Use mkBefore so this is prepended to (not override) any user-set extraOptions
        virtualisation.oci-containers.containers.jellyfin.extraOptions = mkBefore [
          # Pass the integrated GPU device for VAAPI (AMD/Intel) or QSV (Intel)
          "--device=/dev/dri:/dev/dri"
        ];
      })
    ]);
  }
