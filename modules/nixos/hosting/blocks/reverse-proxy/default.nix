{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.reverse-proxy;
in
  with lib; {
    imports = [
      ./traefik
    ];

    options.hosting.blocks.reverse-proxy = {
      type = mkOption {
        type = with types; enum ["traefik"];
        default = "traefik";
        description = "The type of reverse proxy to use";
        example = "traefik";
      };

      containers = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              endpoint = mkOption {
                type = with types; str;
                default = null;
                description = "The endpoint for the container";
                example = "admin.ts.${cfg.domain.fqdn}";
              };

              port = mkOption {
                type = with types; int;
                default = null;
                description = "The port for the container";
                example = 8080;
              };
            };
          });
        default = {};
        description = "The function to generate the required oci-containers attributes for integration with the reverse proxy";
        example = {
          portainer = {
            endpoint = "admin.ts.${cfg.domain.fqdn}";
            port = 9000;
          };
        };
      };

      domain = {
        fqdn = mkOption {
          type = with types; nullOr str;
          default = null;
          description = "The fully qualified domain name for all other traefik endpoints to be based off of";
          example = "cryptic-coders.net";
        };

        provider = {
          type = mkOption {
            type = with types; nullOr (enum ["cloudflare"]);
            default = null;
            description = "The provider to use for the traefik cert resolver";
            example = "cloudflare";
          };

          name = mkOption {
            type = with types; nullOr str;
            default =
              if cfg.domain.provider.type == "cloudflare"
              then "cf"
              else null;
            description = "The name of the provider to use for the traefik cert resolver";
            example = "cf";
          };

          challengeType = mkOption {
            type = with types; enum ["tls" "dns"];
            default = "dns";
            description = "The type of challenge to use for the traefik cert resolver";
            example = "tls";
          };
        };
      };
    };
  }
