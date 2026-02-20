{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.reverse-proxy;
in
  with lib; {
    imports = [
      ./providers
    ];

    config = mkIf (config.hosting.enable && cfg.type == "traefik" && cfg.domain.fqdn != null) {
      virtualisation.oci-containers.containers = mkMerge [
        {
          traefik-socket-proxy = {
            image = "tecnativa/docker-socket-proxy:latest";
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock:ro"
            ];
            environment = {
              CONTAINERS = "1";
              NETWORKS = "1";
              EVENTS = "1";
              PING = "1";
              VERSION = "1";
            };
            networks = ["admin_traefik-public"];
          };
          traefik = {
            image = "traefik:latest";
            dependsOn = ["traefik-socket-proxy"];
            cmd = [
              "--entrypoints.web.address=:80"
              "--entrypoints.websecure.address=:443"
              "--entrypoints.websecure.http.tls=true"
              "--providers.docker=true"
              "--providers.docker.exposedbydefault=false"
              "--providers.docker.endpoint=tcp://traefik-socket-proxy:2375"
              "--providers.docker.network=admin_traefik-public"
              "--api.dashboard=true"
              "--api.insecure=false"
              "--log.level=INFO"
              "--accesslog=true"
              "--metrics.prometheus=true"
              "--entrypoints.web.http.redirections.entrypoint.to=websecure"
              "--entrypoints.web.http.redirections.entrypoint.scheme=https"
              "--entrypoints.web.http.redirections.entrypoint.permanent=true"

              "--certificatesresolvers.${cfg.domain.provider.name}.acme.email=admin@${cfg.domain.fqdn}"
              "--certificatesresolvers.${cfg.domain.provider.name}.acme.storage=/acme/acme.json"
              "--certificatesresolvers.${cfg.domain.provider.name}.acme.${cfg.domain.provider.challengeType}challenge=true"
              "--certificatesresolvers.${cfg.domain.provider.name}.acme.${cfg.domain.provider.challengeType}challenge.provider=${cfg.domain.provider.type}"
            ];
            volumes = [
              "admin_traefik-certs:/acme"
            ];
            networks = ["admin_traefik-public"];
            ports = ["80:80" "443:443"];
          };
        }
        (mkIf (cfg.containers != null) (mapAttrs (name: attrs: {
            ${name} = {
              labels = [
                "traefik.enable=true"
                "traefik.http.routers.${name}.entrypoints=websecure"
                "traefik.http.routers.${name}.rule=Host(`${attrs.endpoint}`)"
                "traefik.http.routers.${name}.tls=true"
                "traefik.http.routers.${name}.tls.certresolver=${cfg.domain.provider.name}"
                "traefik.http.services.${name}.loadbalancer.server.port=${attrs.port}"
              ];
            };
          })
          cfg.containers))
      ];
    };
  }
