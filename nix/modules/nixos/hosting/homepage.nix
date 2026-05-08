{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.homepage;
  proxyCfg = config.hosting.proxy;

  proxyServices = proxyCfg.services;
  localDashboardUrl = "http://127.0.0.1:${toString cfg.listenPort}";

  subdomainPrefix =
    if proxyCfg.dns.localSubdomain != ""
    then ".${proxyCfg.dns.localSubdomain}"
    else "";

  hostFor = serviceName:
    if serviceName == "default"
    then "${proxyCfg.dns.localSubdomain}.${proxyCfg.dns.baseDomain}"
    else "${serviceName}${subdomainPrefix}.${proxyCfg.dns.baseDomain}";
  hrefFor = serviceName: path: "https://${hostFor serviceName}${path}";

  # Caddy binds loopback only; Jellyfin is exposed on the tailnet via Tailscale Serve (see hosting.media.jellyfin).
  hrefForCard = serviceName: path:
    if cfg.tailnetOrigin != null && serviceName == "media" && path == "/watch"
    then "${cfg.tailnetOrigin}/web"
    else hrefFor serviceName path;

  normalizePathLabel = path:
    lib.replaceStrings ["/"] [" "] (lib.removePrefix "/" path);

  serviceCardsFor = serviceName: serviceDef: let
    main = {
      "${lib.toUpper (lib.substring 0 1 serviceName)}${lib.substring 1 (builtins.stringLength serviceName - 1) serviceName}" = {
        description = "Primary ${serviceName} endpoint";
        href = hrefFor serviceName "";
      };
    };

    extra =
      lib.mapAttrsToList (path: _: {
        "${serviceName} ${normalizePathLabel path}" = {
          description = "${serviceName} ${path}";
          href = hrefForCard serviceName path;
        };
      })
      serviceDef.extraPaths;
  in
    [main] ++ extra;

  dynamicServiceCards = lib.concatLists (lib.mapAttrsToList serviceCardsFor proxyServices);
  externalServiceLayerCards = lib.optional (cfg.externalServiceLayer.url != null) {
    "${cfg.externalServiceLayer.name}" = {
      description = "External k3s service-layer homepage";
      href = cfg.externalServiceLayer.url;
    };
  };
in
  with lib; {
    options.hosting.homepage = {
      enable = mkEnableOption "Enable Homepage Dashboard for hosted services";

      listenPort = mkOption {
        type = types.port;
        default = 8082;
        description = "Port used by services.homepage-dashboard.";
      };

      browserStartUrl = mkOption {
        type = types.str;
        default = localDashboardUrl;
        readOnly = true;
        description = "Direct local URL intended for browser homepage/start-page settings.";
      };

      externalServiceLayer = {
        name = mkOption {
          type = types.str;
          default = "Cluster Service Layer";
          description = "Label shown in homepage-dashboard for external service-layer link.";
        };

        url = mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "https://cluster.example.com";
          description = "Optional external service-layer homepage URL (e.g. k3s dashboard).";
        };
      };

      tailnetOrigin = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "https://zephyrus";
        description = ''
          HTTPS origin for Tailscale-friendly bookmarks (no trailing slash).
          When non-null, the Jellyfin shortcut (media → /watch) uses
          `''${tailnetOrigin}/web` instead of the local-only Caddy hostname so links work from other tailnet devices
          (aligned with Tailscale Serve on port 443).
          Defaults to `https://''${networking.hostName}` when Tailscale is enabled (override with `null` if MagicDNS differs).
        '';
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        services.homepage-dashboard = {
          enable = true;
          inherit (cfg) listenPort;
          openFirewall = false;

          settings = {
            title = "Data Fortress";
            theme = "dark";
            color = "slate";
          };

          widgets = [
            {
              resources = {
                cpu = true;
                memory = true;
                disk = "/";
              };
            }
            {
              datetime = {
                text_size = "md";
                format = {
                  dateStyle = "short";
                  timeStyle = "short";
                };
              };
            }
          ];

          services =
            [
              {
                "Hosted Services" = dynamicServiceCards;
              }
            ]
            ++ optionals (externalServiceLayerCards != []) [
              {
                "External Control" = externalServiceLayerCards;
              }
            ];
        };
      }
      (mkIf config.core.networking.tailscale.enable {
        hosting.homepage.tailnetOrigin = mkDefault "https://${config.networking.hostName}";
      })
    ]);
  }
