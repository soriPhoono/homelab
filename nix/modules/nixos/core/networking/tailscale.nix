{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.core.networking.tailscale;
in
  with lib; {
    options.core.networking.tailscale = {
      enable = mkEnableOption "Enable tailscale always on vpn";

      auth = {
        enable = mkEnableOption "Enable tailscale authkey auto login";
        internal = mkEnableOption "Enable internal provisioning of the required secret for authentication";
      };

      serve = {
        enable = mkEnableOption "Enable tailscale serve";

        services = mkOption {
          type = with types;
            attrsOf (submodule {
              options = {
                name = mkOption {
                  type = with types; nullOr str;
                  default = null;
                  description = "Unused; reserved for future Tailscale serve metadata";
                };

                proxy = mkOption {
                  type = with types; attrsOf str;
                  default = {};
                  description = "List of endpoints to expose via tailscale serve";
                };
              };
            });
          default = {};
          description = "List of services to expose on tailscale serve";
          example = {
            plex = {
              proxy = {
                "tcp:443" = "https://localhost:443";
                "tcp:80" = "http://localhost:80";
              };
            };
          };
        };
      };
    };

    config = lib.mkIf cfg.enable (mkMerge [
      {
        services.tailscale = {
          enable = true;
          useRoutingFeatures = "client";
          openFirewall = true;
          disableUpstreamLogging = true;
        };
      }
      (mkIf (cfg.serve.enable && cfg.serve.services != {}) {
        services.tailscale.serve = {
          enable = true;
          services =
            mapAttrs (_name: value: {
              endpoints = value.proxy;
            })
            cfg.serve.services;
        };
      })
      (lib.optionalAttrs (options ? sops) (mkIf cfg.auth.internal {
        sops.secrets."api/tailscale" = {};

        services.tailscale = {
          authKeyFile = config.sops.secrets."api/tailscale".path;
        };
      }))
      (mkIf config.core.networking.network-manager.enable {
        networking.networkmanager.unmanaged = [config.services.tailscale.interfaceName];
      })
    ]);
  }
