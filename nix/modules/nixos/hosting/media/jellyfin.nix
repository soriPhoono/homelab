{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.core) mkContainerUser;

  mediaCfg = config.hosting.media;
  cfg = mediaCfg.jellyfin;

  name = "jellyfin";
  group = "media";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.jellyfin = {
      enable = mkEnableOption "Enable jellyfin container for media streaming";
      acceleration.enable = mkEnableOption "Enable hardware acceleration (VAAPI/QSV) on the integrated GPU";

      container.publication = mkOption {
        type = types.listOf (types.enum ["local" "tailscale"]);
        default = ["local"];
        description = ''
          Determines where the container is published to. "local" for the local
          network via traefik, "tailscale" for the tailscale network via docktail
        '';
      };
    };

    config = mkIf mediaCfg.enable (mkMerge [
      (mkContainerUser {
        inherit name group config configurationDirectory;
      })
      {
        assertions = [
          {
            message = "Container can't be exposed to tailscale on a machine that is not a tailnet member";
            assertion = !(elem "tailscale" cfg.container.publication) || config.services.tailscale.enable;
          }
        ];

        hosting.proxy.traefik.enable = elem "local" cfg.container.publication;

        virtualisation.oci-containers.containers.jellyfin = {
          image = "linuxserver/jellyfin:10.11.11";

          networks = ["proxy"];

          environment = {
            PUID = toString config.users.users.${name}.uid;
            PGID = toString config.users.groups.${name}.gid;

            TZ = config.core.timeZone;
          };

          volumes = [
            "${configurationDirectory}:/config"
            "/mnt/local/${group}/shows:/data/tvshows"
            "/mnt/local/${group}/movies:/data/movies"
            "/mnt/local/${group}/music:/data/music"
          ];

          labels = mkMerge [
            (mkIf (elem "local" cfg.container.publication) {
              "traefik.enable" = "true";
              "traefik.http.routers.${name}.entrypoints" = "websecure";
              "traefik.http.routers.${name}.tls" = "true";
              "traefik.http.routers.${name}.tls.certresolver" = "le";
              "traefik.http.services.${name}.loadbalancer.server.port" = "8096";
              "traefik.http.routers.${name}.rule" = "Host(`media.${config.hosting.proxy.dns.subdomain}.${config.hosting.proxy.dns.domain}`)";
            })
            (mkIf (elem "tailscale" cfg.container.publication) {
              })
          ];
        };
      }
      # ── Hardware acceleration (VAAPI/QSV) ────────────────
      (mkIf cfg.acceleration.enable {
        users.users.${name}.extraGroups = ["render" "video"];
        # Use mkBefore so this is prepended to (not override) any user-set extraOptions
        virtualisation.oci-containers.containers.jellyfin.extraOptions = mkBefore [
          # Pass the integrated GPU device for VAAPI (AMD/Intel) or QSV (Intel)
          "--device=/dev/dri/renderD128:/dev/dri/renderD128"
          "--device=/dev/dri/card0:/dev/dri/card0"
        ];
      })
    ]);
  }
