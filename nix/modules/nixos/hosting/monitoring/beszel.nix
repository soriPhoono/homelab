{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "beszel";
  cfg = config.hosting.monitoring.${name};
  configurationDirectory = "/var/lib/${name}";
  privateNetwork = "${name}-internal";
  agentName = "${name}-agent";
in
  with lib; {
    options.hosting.monitoring.${name} =
      (mkContainerOption {
        inherit name;
        description = "Lightweight server and container monitoring";
      })
      // {
        agent = {
          enable = mkEnableOption "Enable the local Beszel agent";

          keySecret = mkOption {
            type = types.str;
            default = "api/beszel-agent-key";
            description = "SOPS secret containing the Beszel agent public key.";
          };

          tokenSecret = mkOption {
            type = types.str;
            default = "api/beszel-agent-token";
            description = "SOPS secret containing the Beszel agent token.";
          };
        };
      };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "beszel requires the Docker hosting platform to be enabled.";
          }
        ];

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
          "d ${configurationDirectory}/hub 0750 1000 1000 -"
          "d ${configurationDirectory}/agent 0750 1000 1000 -"
          "d ${configurationDirectory}/socket 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "henrygd/beszel:0.18.8";
            serviceName = "monitoring";
            servicePort = 8090;
          })
          {
            networks = ["tailscale" privateNetwork];
            environment = {
              APP_URL = "https://${config.networking.hostName}-monitoring.xerus-augmented.ts.net";
            };
            volumes = [
              "${configurationDirectory}/hub:/beszel_data"
              "${configurationDirectory}/socket:/beszel_socket"
            ];
          }
        ];
      }
      (mkIf cfg.agent.enable {
        sops.secrets.${cfg.agent.keySecret} = {};
        sops.secrets.${cfg.agent.tokenSecret} = {};

        virtualisation.oci-containers.containers.${agentName} = mkMerge [
          (mkContainer {
            name = agentName;
            inherit config;
            cfg = cfg // {container = cfg.container // {publication = [];};};
            image = "henrygd/beszel-agent:0.18.8";
          })
          {
            networks = [privateNetwork];
            environment = {
              HUB_URL = "http://${name}:8090";
              LISTEN = "/beszel_socket/beszel.sock";
              SYSTEM_NAME = config.networking.hostName;
            };
            environmentFiles = [
              config.sops.templates."hosting/monitoring/beszel-agent.env".path
            ];
            volumes = [
              "${configurationDirectory}/agent:/var/lib/beszel-agent"
              "${configurationDirectory}/socket:/beszel_socket"
              "/var/run/docker.sock:/var/run/docker.sock:ro"
            ];
          }
        ];
      })
      (mkIf cfg.agent.enable {
        sops.templates."hosting/monitoring/beszel-agent.env".content = ''
          KEY=${config.sops.placeholder.${cfg.agent.keySecret}}
          TOKEN=${config.sops.placeholder.${cfg.agent.tokenSecret}}
        '';
      })
    ]);
  }
