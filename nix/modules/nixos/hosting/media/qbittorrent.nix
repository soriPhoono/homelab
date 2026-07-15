{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.core) mkContainerUser;

  cfg = config.hosting.media.qbittorrent;

  name = "qbittorrent";
  group = "media";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.qbittorrent = {
      enable = mkEnableOption "Enable qBittorrent BitTorrent client";

      container.publication = mkOption {
        type = types.listOf (types.enum ["local" "tailscale"]);
        default = ["local"];
        description = ''
          The publication type for the container. Can be "local" or "tailscale".
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      (mkContainerUser {
        inherit name group config configurationDirectory;
      })
      {
        virtualisation.oci-containers.containers.qbittorrent = {
          image = "linuxserver/qbittorrent:5.2.3";

          environment = {
            PUID = toString config.users.users.${name}.uid;
            PGID = toString config.users.groups.${name}.gid;
            WEBUI_PORT = "8080";
            TORRENTING_PORT = "6881";
            TZ = config.time.timeZone;
          };

          volumes = [
            "${configurationDirectory}:/config"
            "/mnt/local/media/downloads:/downloads"
          ];

          networks = ["proxy"];

          labels = mkMerge [
            (mkIf (elem "local" cfg.container.publication) {
              "traefik.enable" = "true";
              "traefik.http.routers.qbittorrent.rule" = "Host(`downloads.${config.hosting.proxy.dns.subdomain}.${config.hosting.proxy.dns.domain}`) ";
              "traefik.http.routers.qbittorrent.entrypoints" = "websecure";
              "traefik.http.routers.qbittorrent.tls" = "true";
              "traefik.http.routers.qbittorrent.tls.certresolver" = "le";
              "traefik.http.services.qbittorrent.loadbalancer.server.port" = "8080";
            })
          ];
        };
      }
    ]);
  }
