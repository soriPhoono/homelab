{
  lib,
  config,
  ...
}: let
  uids = import ../uids.nix;
  cfg = config.hosting.media.bookshelf;
in
  with lib; {
    options.hosting.media.bookshelf = {
      enable = mkEnableOption "Enable Bookshelf ebook and audiobook collection manager";

      port = mkOption {
        type = types.port;
        default = 8787;
        description = "Port for the Bookshelf web interface";
      };

      image = mkOption {
        type = types.str;
        default = "ghcr.io/pennydreadful/bookshelf:hardcover";
        defaultText = literalExpression ''"ghcr.io/pennydreadful/bookshelf:hardcover"'';
        description = ''
          Docker image for Bookshelf.
          Uses the hardcover metadata tag by default.
          Available: hardcover (recommended), softcover (Goodreads, backward-compatible with Readarr).
        '';
      };

      configDir = mkOption {
        type = types.str;
        default = "/var/lib/bookshelf";
        description = "Host directory for Bookshelf configuration";
      };

      domain = mkOption {
        type = types.str;
        default = "books.${config.hosting.proxy.dns.localSubdomain}.${config.hosting.proxy.dns.baseDomain}";
        defaultText = literalExpression ''"books.&{localSubdomain}.&{baseDomain}"'';
        description = ''
          The external domain for the Bookshelf web interface (used for Traefik routing).
        '';
      };

      userUid = mkOption {
        type = types.int;
        default = uids.media.bookshelf.uid;
        description = ''
          UID for file ownership on mounted volumes.
          Should match the owner of your book/media files on the host.
        '';
      };

      userGid = mkOption {
        type = types.int;
        default = uids.media.bookshelf.gid;
        description = ''
          GID for file ownership on mounted volumes.
          Should match the group of your book/media files on the host.
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
          users.bookshelf = {
            isSystemUser = true;
            uid = mkDefault cfg.userUid;
            group = config.users.groups.bookshelf.name;
          };
          groups = {
            bookshelf = {
              gid = mkDefault cfg.userGid;
            };
            media.members = [
              config.users.users.bookshelf.name
            ];
          };
        };

        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 ${toString cfg.userUid} ${toString cfg.userGid} -"
        ];

        virtualisation.oci-containers.containers.bookshelf = {
          inherit (cfg) image;
          autoStart = true;
          networks = ["proxy"];

          volumes =
            [
              "${cfg.configDir}:/config"
              "/mnt/local/media/books:/books"
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
              "traefik.http.routers.bookshelf.rule" = "Host(`${cfg.domain}`)";
              "traefik.http.routers.bookshelf.entrypoints" = "websecure";
              "traefik.http.routers.bookshelf.tls" = "true";
              "traefik.http.routers.bookshelf.tls.certresolver" = "le";
              "traefik.http.services.bookshelf.loadbalancer.server.port" = toString cfg.port;
            }
            // cfg.extraLabels;

          inherit (cfg) extraOptions;
        };
      }
    ]);
  }
