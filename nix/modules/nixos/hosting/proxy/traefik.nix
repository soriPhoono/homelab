{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  proxyCfg = config.hosting.proxy;
  cfg = proxyCfg.traefik;

  name = "traefik";
  configurationDirectory = "/etc/${name}";
in
  with lib; {
    options.hosting.proxy.traefik = mkContainerOption {
      inherit name;
      description = "The reverse proxy Traefik, used to route traffic to other services.";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        virtualisation.oci-containers.containers.traefik = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "traefik:v3.7";
            subdomain = "proxy";
            service = "api@internal";
            publish = true;
          })
          {
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
              (
                if config.virtualisation.oci-containers.backend == "podman"
                then "/run/user/${toString config.users.users.microserver.uid}/podman/podman.sock:/var/run/docker.sock:ro"
                else "/var/run/docker.sock:/var/run/docker.sock:ro"
              )
              # Static config directory (for future traefik.yml additions)
              "${configurationDirectory}:/etc/traefik"
              # ACME certificate storage
              "${configurationDirectory}/letsencrypt:/letsencrypt"
            ];

            ports = [
              "80:80"
              "443:443"
            ];
          }
        ];

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
          "d ${configurationDirectory}/letsencrypt 0755 microserver microserver -"
        ];
      }
    ]);
  }
