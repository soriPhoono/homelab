{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.homepage;
  proxyCfg = config.hosting.proxy;

  proxyServices = proxyCfg.services;

  subdomainPrefix =
    if proxyCfg.dns.localSubdomain != ""
    then "${proxyCfg.dns.localSubdomain}."
    else "";

  hostFor = serviceName:
    if serviceName == "default"
    then "${subdomainPrefix}${proxyCfg.dns.baseDomain}"
    else "${serviceName}.${subdomainPrefix}${proxyCfg.dns.baseDomain}";
  hrefFor = serviceName: path: "https://${hostFor serviceName}${path}";

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
          href = hrefFor serviceName path;
        };
      })
      serviceDef.extraPaths;
  in
    [main] ++ extra;

  dynamicServiceCards = lib.concatLists (lib.mapAttrsToList serviceCardsFor proxyServices);
in
  with lib; {
    options.hosting.homepage = {
      enable = mkEnableOption "Enable Homepage Dashboard for hosted services";

      listenPort = mkOption {
        type = types.port;
        default = 8082;
        description = "Port used by services.homepage-dashboard.";
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

          services = [
            {
              "Hosted Services" = dynamicServiceCards;
            }
          ];
        };
      }
    ]);
  }
