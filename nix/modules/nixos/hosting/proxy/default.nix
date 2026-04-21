{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.proxy;
in
  with lib; {
    imports = [
      ./caddy.nix
    ];

    options.hosting.proxy = {
      enable = mkEnableOption "Enable proxy services";

      type = mkOption {
        type = types.enum ["caddy"];
        default = "caddy";
        description = "Type of proxy to use";
      };

      dns = {
        provider = mkOption {
          type = types.enum ["cloudflare"];
          default = "cloudflare";
          description = "DNS provider for Caddy TLS certificates";
        };

        email = mkOption {
          type = types.str;
          description = "Email for Caddy TLS certificates";
          example = "[EMAIL_ADDRESS]";
        };

        baseDomain = mkOption {
          type = types.str;
          description = "Base domain (e.g., cryptic-coders.net)";
          example = "cryptic-coders.net";
        };

        localSubdomain = mkOption {
          type = types.str;
          default = "local";
          description = "Subdomain for local services (e.g., local)";
        };
      };

      services = mkOption {
        type = types.attrsOf (types.submodule {
          options = let
            proxyConfig = with types;
              submodule {
                options = {
                  proxyPort = mkOption {
                    type = int;
                    description = "The port to proxy to";
                    example = 8096;
                  };
                  handlePath = mkEnableOption "Strip the /{path} from the url before proxying";
                  extraConfig = mkOption {
                    type = nullOr str;
                    default = null;
                    description = "Extra Caddyfile configuration";
                    example = "reverse_proxy localhost:8096";
                  };
                };
              };
          in {
            proxyPort = mkOption {
              type = types.int;
              description = "The port to proxy to";
              example = 8096;
            };
            extraConfig = mkOption {
              type = with types; nullOr str;
              default = null;
              description = "Extra Caddyfile configuration";
              example = "reverse_proxy localhost:8096";
            };
            extraPaths = mkOption {
              type = types.attrsOf proxyConfig;
              default = {};
              description = "Virtual folders (paths) and their ports";
              example = {
                "/watch" = {
                  proxyPort = 8096;
                  handlePath = true;
                };
              };
            };
          };
        });
        default = {};
        description = "Services to expose via proxy";
      };
    };

    config = mkIf cfg.enable {
      hosting.proxy = {
        caddy.enable = cfg.type == "caddy";
      };
    };
  }
