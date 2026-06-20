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

      type = mkOption {
        type = types.enum [
          "traefik"
        ];
        default = "traefik";
        description = ''
          The reverse proxy backend to use for service exposure.
          Currently only "traefik" is supported.
        '';
      };

      dns = {
        provider = mkOption {
          type = types.enum ["cloudflare"];
          default = "cloudflare";
          description = "DNS provider for proxy TLS certificates";
        };

        email = mkOption {
          type = types.str;
          description = "Email for TLS certificate registration (used by ACME)";
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
    };

    config = mkIf cfg.enable {
      hosting.proxy = {
        traefik.enable = cfg.type == "traefik";
      };
    };
  }
