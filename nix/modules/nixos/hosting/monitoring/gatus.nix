{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "gatus";
  cfg = config.hosting.monitoring.${name};
  configurationDirectory = "/var/lib/${name}";
  serviceEndpoints =
    [
      {
        name = "Dozzle";
        host = "dozzle";
        port = 8080;
      }
      {
        name = "Beszel";
        host = "beszel";
        port = 8090;
      }
    ]
    ++ lib.optional config.hosting.services.forgejo.enable {
      name = "Forgejo";
      host = "forgejo";
      port = 3000;
    }
    ++ lib.optional config.hosting.development.buildkit.enable {
      name = "BuildKit";
      host = "buildkit";
      port = 1234;
    };
  endpointConfig =
    lib.concatMapStringsSep "\n" (endpoint: ''
      - name: ${endpoint.name}
        group: Developer services
        url: tcp://${endpoint.host}:${toString endpoint.port}
        interval: 30s
        conditions:
          - "[CONNECTED] == true"
    '')
    serviceEndpoints;
  gatusConfig = pkgs.writeText "gatus-config.yaml" ''
    web:
      port: 8080
    storage:
      type: sqlite
      path: /data/gatus.db
    endpoints:
    ${endpointConfig}
  '';
in
  with lib; {
    options.hosting.monitoring.${name} = mkContainerOption {
      inherit name;
      description = "Declarative service health dashboard";
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = config.hosting.platforms.docker.enable;
          message = "gatus requires the Docker hosting platform to be enabled.";
        }
      ];

      systemd.tmpfiles.rules = [
        "d ${configurationDirectory} 0750 1000 1000 -"
      ];

      virtualisation.oci-containers.containers.${name} = mkMerge [
        (mkContainer {
          inherit name cfg config;
          image = "twinproduction/gatus:v5.36.0";
          serviceName = "status";
          servicePort = 8080;
        })
        {
          networks = ["tailscale"];
          environment = {
            GATUS_CONFIG_PATH = "/config/config.yaml";
            TZ = config.time.timeZone;
          };
          volumes = [
            "${configurationDirectory}:/data"
            "${gatusConfig}:/config/config.yaml:ro"
          ];
        }
      ];
    };
  }
