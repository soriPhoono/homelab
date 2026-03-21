{
  lib,
  config,
  ...
}: let
  inherit (config.hosting.single-node.modules) reverse-proxy;
in
  with lib; {
    options.hosting.single-node.modules.traefik = {
    };

    config = mkIf (reverse-proxy.type == "traefik") {
      virtualisation.oci-containers.containers."traefik" = {
        image = "traefik:v3";
        cmd = [
          # Entrypoints
          "--entrypoints.web.address=:80"
          "--entrypoints.websecure.address=:443"

          # Entrypoints Redirection (HTTP to HTTPS)
          "--entrypoints.web.http.redirections.entryPoint.to=websecure"
          "--entrypoints.web.http.redirections.entryPoint.scheme=https"

          # Docker Provider
          "--providers.docker=true"
          "--providers.docker.exposedByDefault=false"
          "--providers.docker.endpoint=tcp://socket_proxy:2375"

          # Certificate Resolvers
          # 1. HTTP Challenge (Public)
          "--certificatesresolvers.http.acme.httpchallenge=true"
          "--certificatesresolvers.http.acme.httpchallenge.entrypoint=web"
          "--certificatesresolvers.http.acme.email=${reverse-proxy.acmeEmail}"
          "--certificatesresolvers.http.acme.storage=/letsecrypt/acme.json"

          # 2. DNS Challenge (Cloudflare - for local/private domains)
          "--certificatesresolvers.dns.acme.dnschallenge=true"
          "--certificatesresolvers.dns.acme.dnschallenge.entrypoint=web"
          "--certificatesresolvers.dns.acme.dnschallenge.provider=cloudflare"
          "--certificatesresolvers.dns.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
          "--certificatesresolvers.dns.acme.email=${reverse-proxy.acmeEmail}"
          "--certificatesresolvers.dns.acme.storage=/letsecrypt/acme.json"

          # API/Dashboard
          "--api.dashboard=true"

          # Logging
          "--log.level=INFO"
        ];
      };
    };
  }
