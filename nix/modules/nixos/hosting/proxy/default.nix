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
      };

      local = {
        provider = mkOption {
          type = types.enum ["traefik"];
          description = "The provider of the local network service";
          default = null;
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
    };

    config = mkIf cfg.enable (mkMerge [
      {
        boot.kernel.sysctl = {
          "net.ipv4.ip_unprivileged_port_start" = 80;
        };

        hosting = {
          enable = true;
          proxy = {
            traefik.enable = cfg.local.provider == "traefik";
          };
        };
      }
      (mkIf (cfg.local.provider == "traefik") (mkMerge [
        (mkIf (cfg.dns.provider == "cloudflare") {
          sops = {
            secrets."api/cloudflare-${cfg.local.domain}" = {};
            templates."hosting/traefik-${cfg.local.domain}.env" = {
              owner = "microserver";
              group = "microserver";
              mode = "0400";
              content = ''
                CF_DNS_API_TOKEN=${config.sops.placeholder."api/cloudflare-${cfg.local.domain}"}
                LEGO_DISABLE_CNAME_SUPPORT=true
              '';
            };
          };

          virtualisation.oci-containers.containers.traefik = {
            environmentFiles = [
              config.sops.templates."hosting/traefik-${cfg.local.domain}.env".path
            ];
            cmd = [
              "--certificatesresolvers.le.acme.dnschallenge.provider=cloudflare"
              "--certificatesresolvers.le.acme.dnschallenge.resolvers=1.1.1.1:53,8.8.8.8:53"
              "--certificatesresolvers.le.acme.dnschallenge.propagation.disableANSChecks=true"
              "--certificatesresolvers.le.acme.email=${cfg.dns.email}"
            ];
          };
        })
      ]))
    ]);
  }
