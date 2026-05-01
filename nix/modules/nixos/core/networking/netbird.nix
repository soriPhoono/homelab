{
  lib,
  config,
  ...
}: let
  cfg = config.core.networking.netbird;
in
  with lib; {
    options.core.networking.netbird = {
      enable = mkEnableOption "Enable NetBird client VPN";

      auth = {
        enable = mkEnableOption "Enable NetBird setup-key auto login";
      };

      clientName = mkOption {
        type = types.str;
        default = "wt0";
        description = "NetBird client name under services.netbird.clients.";
      };

      openFirewall = mkOption {
        type = types.bool;
        default = true;
        description = "Open the NetBird client listening port in the firewall.";
      };

      port = mkOption {
        type = types.port;
        default = 51820;
        description = "Port the NetBird client listens on.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.netbird = {
          enable = true;
          useRoutingFeatures = "client";
          ui.enable = true;

          clients.${cfg.clientName} = {
            inherit (cfg) openFirewall port;

            openInternalFirewall = true;
          };
        };
      }
      (mkIf (cfg.auth.enable && options ? sops) {
        sops.secrets."api/netbird-token" = {};

        services.netbird = {
          clients.${cfg.clientName}.login = {
            enable = true;
            setupKeyFile = config.sops.secrets."api/netbird-token".path;
          };
        };
      })
      (mkIf config.core.networking.network-manager.enable {
        networking.networkmanager.unmanaged = [cfg.clientName];
      })
    ]);
  }
