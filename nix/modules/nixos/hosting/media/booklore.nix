{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.booklore;
in
  with lib; {
    options.hosting.media.booklore = {
      enable = mkEnableOption "Enable BookLore digital library with built-in reader";

      port = mkOption {
        type = types.port;
        default = 6060;
        description = "Port for the BookLore web interface";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/booklore-app/booklore:latest";
        description = ''
          Docker image for BookLore.
          Uses the official image from GitHub Container Registry.
        '';
      };

      mariaDbImage = mkOption {
        type = types.str;
        default = "lscr.io/linuxserver/mariadb:11.4.5";
        description = "Docker image for the MariaDB database companion";
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/booklore";
        description = "Host directory for BookLore application data";
      };

      mariaDbConfigDir = mkOption {
        type = types.str;
        default = "/var/lib/booklore-mariadb";
        description = "Host directory for MariaDB configuration and data";
      };

      booksDir = mkOption {
        type = types.str;
        default = "/mnt/local/media/books";
        description = "Host directory for book files mounted into the container";
      };

      bookdropDir = mkOption {
        type = types.str;
        default = "/mnt/local/media/bookdrop";
        description = "Host directory for auto-import book drop folder";
      };

      domain = mkOption {
        type = types.str;
        default = "library.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"library.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the BookLore web interface (used for Traefik routing).
        '';
      };

      database = {
        name = mkOption {
          type = types.str;
          default = "booklore";
          description = "MariaDB database name for BookLore";
        };
        user = mkOption {
          type = types.str;
          default = "booklore";
          description = "MariaDB username for BookLore";
        };
        password = mkOption {
          type = types.str;
          default = "booklore";
          description = "MariaDB password for BookLore";
        };
        rootPassword = mkOption {
          type = types.str;
          default = "booklore";
          description = "MariaDB root password";
        };
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.booklore.uid;
        description = ''
          UID for file ownership on mounted volumes.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.booklore.gid;
        description = ''
          GID for file ownership on mounted volumes.
        '';
      };

      bookdropUserUid = mkOption {
        type = types.int;
        default = uids.media.bookshelf.uid;
        description = ''
          UID for the bookdrop directory so Bookshelf can write to it.
          Defaults to the Bookshelf user UID.
        '';
      };

      extraVolumes = mkOption {
        type = types.listOf types.str;
        default = [];
        description = ''
          Additional volume mounts for the BookLore container.
          Each entry should be in Docker volume format: "/host/path:/container/path[:mode]"
        '';
      };

      extraLabels = mkOption {
        type = types.attrsOf types.str;
        default = {};
        description = "Additional Docker labels for the BookLore container (e.g., Traefik middleware).";
      };

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra Docker options passed directly to the BookLore container runtime.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        users = {
          users.booklore = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.booklore.name;
          };
          groups = {
            booklore = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.booklore.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directories exist
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
          "d ${cfg.mariaDbConfigDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
          "d ${cfg.booksDir} 0775 ${toString cfg.bookdropUserUid} ${toString config.users.groups.media.gid} -"
          "d ${cfg.bookdropDir} 0775 ${toString cfg.bookdropUserUid} ${toString config.users.groups.media.gid} -"
        ];

        # ── MariaDB companion container ─────────────────────
        virtualisation.oci-containers.containers.booklore-mariadb = {
          image = cfg.mariaDbImage;
          autoStart = true;
          networks = ["proxy"];

          volumes = [
            "${cfg.mariaDbConfigDir}:/config"
          ];

          environment =
            {
              PUID = toString cfg.userUid;
              PGID = toString cfg.userGid;
              MYSQL_ROOT_PASSWORD = cfg.database.rootPassword;
              MYSQL_DATABASE = cfg.database.name;
              MYSQL_USER = cfg.database.user;
              MYSQL_PASSWORD = cfg.database.password;
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };
        };

        # ── BookLore app container ──────────────────────────
        virtualisation.oci-containers.containers.booklore = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];
          dependsOn = ["booklore-mariadb"];

          volumes =
            [
              "${cfg.configDir}:/app/data"
              "${cfg.booksDir}:/books"
              "${cfg.bookdropDir}:/bookdrop"
            ]
            ++ cfg.extraVolumes;

          environment =
            {
              USER_ID = toString cfg.userUid;
              GROUP_ID = toString cfg.userGid;
              DATABASE_URL = "jdbc:mariadb://booklore-mariadb:3306/${cfg.database.name}";
              DATABASE_USERNAME = cfg.database.user;
              DATABASE_PASSWORD = cfg.database.password;
            }
            // optionalAttrs (config.time.timeZone != null) {
              TZ = config.time.timeZone;
            };

          # Traefik auto-discovery labels
          labels =
            {
              "traefik.enable" = "true";
              "traefik.http.routers.booklore.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.booklore.entrypoints" = "websecure";
              "traefik.http.routers.booklore.tls" = "true";
              "traefik.http.routers.booklore.tls.certresolver" = "le";
              "traefik.http.services.booklore.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
