{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.proxy;
in
  with lib; {
    imports = [
      ./traefik.nix
    ];

    options.hosting.proxy = {
      enable = mkEnableOption "Enable proxy services";

      dns = {
        provider = mkOption {
          type = types.enum ["cloudflare"];
          description = ''
            The DNS provider providing support for TLS certificates
          '';
          default = null;
        };

        email = mkOption {
          type = types.str;
          default = null;
          description = "Email for TLS certificate registration (used by ACME)";
          example = "[EMAIL_ADDRESS]";
        };

        domain = mkOption {
          type = types.str;
          default = null;
          description = "Domain to set up DNS-01 Challenge for TLS certificates";
          example = "mydomain.net";
        };

        subdomain = mkOption {
          type = types.str;
          default = "local";
          description = "Subdomain for local services (e.g., local)";
        };
      };

      local = {
        provider = mkOption {
          type = types.enum ["traefik"];
          description = "The provider of the local network service";
          default = null;
        };
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting = {
          uuids.proxy = {};

          proxy = {
            traefik.enable = cfg.local.provider == "traefik";
          };
        };
      }
      (mkIf (cfg.local.provider == "traefik") (mkMerge [
        (mkIf (cfg.dns.provider == "cloudflare") {
          sops = {
            secrets."api/cloudflare-${cfg.dns.domain}" = {};
            templates."hosting/traefik-${cfg.dns.domain}.env" = {
              owner = "traefik";
              group = "traefik";
              mode = "0400";
              content = ''
                CF_DNS_API_TOKEN=${config.sops.placeholder."api/cloudflare-${cfg.dns.domain}"}
              '';
            };
          };

          virtualisation.oci-containers.containers.traefik = {
            environmentFiles = [
              config.sops.templates."hosting/traefik-${cfg.dns.domain}.env".path
            ];
            cmd = [
              "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare"
              "--certificatesresolvers.le.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
              "--certificatesresolvers.le.acme.email=${cfg.dns.email}"
            ];
          };
        })
      ]))
    ]);
  }
