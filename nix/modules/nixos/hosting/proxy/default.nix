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
        type = types.attrsOf (
          types.submodule {
            options = let
              proxyConfig = with types;
                submodule {
                  options = {
                    name = mkOption {
                      type = str;
                      description = "Name of the service (e.g., jellyfin)";
                      example = "jellyfin";
                    };
                    description = mkOption {
                      type = str;
                      description = "Description of the service (e.g., Media Server)";
                      example = "Media Server";
                    };
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
              name = mkOption {
                type = types.str;
                description = "Name of the service (e.g., jellyfin)";
                example = "jellyfin";
              };
              description = mkOption {
                type = types.str;
                description = "Description of the service (e.g., Media Server)";
                example = "Media Server";
              };
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
                    name = "Jellyfin";
                    description = ''
                      Jellyfin is a free software media server that puts you in control of your media. It allows you to organize, manage, and stream your media collection to various devices, both locally and remotely. With features like live TV support, DVR capabilities, and a user-friendly interface, Jellyfin is a popular choice for media enthusiasts looking for an open-source alternative to commercial media servers.
                    '';
                    proxyPort = 8096;
                    handlePath = true;
                  };
                };
              };
            };
          }
        );
        default = {};
        example = {
          media = {
            name = "Seer";
            description = "Media Server Request Interface";
            proxyPort = 5055;
            extraPaths = {
              "/watch" = {
                name = "Jellyfin";
                description = "Jellyfin is a free software media server that puts you in control of your media. It allows you to organize, manage, and stream your media collection to various devices, both locally and remotely. With features like live TV support, DVR capabilities, and a user-friendly interface, Jellyfin is a popular choice for media enthusiasts looking for an open-source alternative to commercial media servers.";
                proxyPort = 8096;
                handlePath = true;
              };
            };
          };
        };
        description = "Services to expose via proxy";
      };
    };

    config = mkIf cfg.enable {
      hosting.proxy = {
        caddy.enable = cfg.type == "caddy";
      };
    };
  }
