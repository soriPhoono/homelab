{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.core) mkContainerUser;

  proxyCfg = config.hosting.proxy;
  cfg = proxyCfg.traefik;

  name = "traefik";
  group = "proxy";
  configurationDirectory = "/etc/${name}";
in
  with lib; {
    options.hosting.proxy.traefik = {
      enable =
        (mkEnableOption "Enable Traefik reverse proxy via Docker")
        // {
          default = proxyCfg.local.provider == "traefik";
        };

      container.publication = mkOption {
        type = types.listOf (types.enum ["local" "tailscale"]);
        default = ["local"];
        description = ''
          Determines where the container is published to. "local" for the local
          network via traefik, "tailscale" for the tailscale network via docktail
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
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

        virtualisation.oci-containers.containers.traefik = {
          image = "traefik:v3.7";

          # Traefik's entrypoint is `traefik`; cmd is passed as CLI args
          cmd = [
            # ── Web EntryPoint ───────────────────────────────────
            "--entrypoints.web.address=:80"
            "--entrypoints.web.http.redirections.entrypoint.to=websecure"
            "--entrypoints.web.http.redirections.entrypoint.scheme=https"
            "--entrypoints.web.http.redirections.entrypoint.permanent=true"

            # ── ACME / Let's Encrypt (DNS-01 via Cloudflare) ─────
            "--certificatesresolvers.le.acme.email=${proxyCfg.dns.email}"
            "--certificatesresolvers.le.acme.storage=/letsencrypt/acme.json"
            "--certificatesresolvers.le.acme.dnschallenge=true"

            # ── Websecure Entrypoint ─────────────────────────────
            "--entrypoints.websecure.address=:443"
            "--entryPoints.websecure.http.tls=true"
            "--entrypoints.websecure.http.tls.certresolver=le"

            # ── Docker Provider ──────────────────────────────────
            "--providers.docker=true"
            "--providers.docker.exposedbydefault=false"
            "--providers.docker.network=proxy"

            # ── Dashboard / API ──────────────────────────────────
            "--api.dashboard=true"
            "--accesslog=true"

            # ── Logging ──────────────────────────────────────────
            "--log.level=INFO"
          ];

          volumes = [
            # Docker socket for the Docker provider (auto-discovers containers)
            "/var/run/docker.sock:/var/run/docker.sock:ro"
            # Static config directory (for future traefik.yml additions)
            "${configurationDirectory}:/etc/traefik"
            # ACME certificate storage
            "${configurationDirectory}/letsencrypt:/letsencrypt"
          ];

          networks = [
            "proxy"
          ];

          ports = [
            "80:80"
            "443:443"
          ];

          labels = mkMerge [
            (mkIf (cfg.container.publication == "local") {
              "traefik.enable" = "true";
              "traefik.http.routers.dashboard.rule" = "Host(`proxy.${proxyCfg.local.dns.subdomain}.${proxyCfg.local.dns.domain}`)";
              "traefik.http.routers.dashboard.entrypoints" = "websecure";
              "traefik.http.routers.dashboard.service" = "api@internal";
              "traefik.http.routers.dashboard.tls" = "true";
              "traefik.http.routers.dashboard.tls.certresolver" = "le";
            })
          ];
        };

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory}/letsencrypt 0755 ${name} ${name} -"
        ];
      }
    ]);
  }
