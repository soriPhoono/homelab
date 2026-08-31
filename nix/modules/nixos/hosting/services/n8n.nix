{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "n8n";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
  privateNetwork = "${name}-internal";
  postgresName = "${name}-postgres";
  serviceHostname = "${config.networking.hostName}-agents";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Workflow automation platform";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "n8n requires the Docker hosting platform to be enabled.";
          }
        ];

        sops.secrets = {
          "api/n8n-encryption-key" = {};
          "api/n8n-postgres-password" = {};
        };

        sops.templates = {
          "hosting/services/n8n.env".content = ''
            N8N_ENCRYPTION_KEY=${config.sops.placeholder."api/n8n-encryption-key"}
            DB_POSTGRESDB_PASSWORD=${config.sops.placeholder."api/n8n-postgres-password"}
          '';
          "hosting/services/n8n-postgres.env".content = ''
            POSTGRES_PASSWORD=${config.sops.placeholder."api/n8n-postgres-password"}
          '';
        };

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
          "d ${configurationDirectory}/postgres 0700 999 999 -"
        ];

        virtualisation.oci-containers.containers = {
          ${postgresName} = {
            image = "postgres:16.15-alpine";
            environment = {
              POSTGRES_DB = "n8n";
              POSTGRES_USER = "n8n";
            };
            environmentFiles = [
              config.sops.templates."hosting/services/n8n-postgres.env".path
            ];
            networks = [privateNetwork];
            volumes = [
              "${configurationDirectory}/postgres:/var/lib/postgresql/data"
            ];
          };

          ${name} = mkMerge [
            (mkContainer {
              inherit name cfg config;
              image = "n8nio/n8n:2.37.6";
              serviceName = "agents";
              servicePort = 5678;
            })
            {
              dependsOn = [postgresName];
              environment = {
                DB_TYPE = "postgresdb";
                DB_POSTGRESDB_DATABASE = "n8n";
                DB_POSTGRESDB_HOST = postgresName;
                DB_POSTGRESDB_PORT = "5432";
                DB_POSTGRESDB_SCHEMA = "public";
                DB_POSTGRESDB_USER = "n8n";
                GENERIC_TIMEZONE = config.time.timeZone;
                N8N_EDITOR_BASE_URL = "https://${serviceHostname}/";
                N8N_ENFORCE_SETTINGS_FILE_PERMISSIONS = "true";
                N8N_HOST = serviceHostname;
                N8N_PORT = "5678";
                N8N_PROTOCOL = "http";
                N8N_PROXY_HOPS = "1";
                N8N_RUNNERS_ENABLED = "true";
                N8N_WEBHOOK_URL = "https://${serviceHostname}/";
                TZ = config.time.timeZone;
              };
              environmentFiles = [
                config.sops.templates."hosting/services/n8n.env".path
              ];
              networks = [privateNetwork];
              volumes = [
                "${configurationDirectory}:/home/node/.n8n"
              ];
            }
          ];
        };
      }
    ]);
  }
