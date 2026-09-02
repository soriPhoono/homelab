{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "outline";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
  privateNetwork = "${name}-internal";
  postgresName = "${name}-postgres";
  redisName = "${name}-redis";
  serviceHostname = "${config.networking.hostName}-wiki";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Outline wiki and knowledge base";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        assertions = [
          {
            assertion = config.hosting.platforms.docker.enable;
            message = "outline requires the Docker hosting platform to be enabled.";
          }
        ];

        sops.secrets = {
          "api/outline-secret-key" = {};
          "api/outline-utils-secret" = {};
          "api/outline-postgres-password" = {};
          "api/smtp-password" = {};
          "api/smtp-from-email" = {};
        };

        sops.templates = {
          "hosting/services/outline.env".content = ''
            SECRET_KEY=${config.sops.placeholder."api/outline-secret-key"}
            UTILS_SECRET=${config.sops.placeholder."api/outline-utils-secret"}
            DATABASE_URL=postgres://outline:${config.sops.placeholder."api/outline-postgres-password"}@${postgresName}:5432/outline?sslmode=disable
            REDIS_URL=redis://${redisName}:6379
            SMTP_HOST=smtp.resend.com
            SMTP_PORT=465
            SMTP_USERNAME=resend
            SMTP_PASSWORD=${config.sops.placeholder."api/smtp-password"}
            SMTP_FROM_EMAIL=${config.sops.placeholder."api/smtp-from-email"}
            SMTP_SECURE=true
          '';
          "hosting/services/outline-postgres.env".content = ''
            POSTGRES_PASSWORD=${config.sops.placeholder."api/outline-postgres-password"}
          '';
        };

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
          "d ${configurationDirectory}/postgres 0700 999 999 -"
          "d ${configurationDirectory}/postgres-18 0700 70 70 -"
          "d ${configurationDirectory}/redis 0750 999 999 -"
          "d ${configurationDirectory}/data 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers = {
          ${postgresName} = {
            image = "postgres:18.6-alpine";
            labels = {
              "wud.tag.include" = ''^\d+\.\d+-alpine$'';
              "wud.tag.transform" = ''^(\d+\.\d+)-alpine$ => $1.0'';
            };
            environment = {
              POSTGRES_DB = "outline";
              POSTGRES_USER = "outline";
            };
            environmentFiles = [
              config.sops.templates."hosting/services/outline-postgres.env".path
            ];
            networks = [privateNetwork];
            volumes = [
              "${configurationDirectory}/postgres-18:/var/lib/postgresql"
            ];
          };

          ${redisName} = {
            image = "redis:8.8.2-alpine";
            labels = {
              "wud.tag.include" = ''^\d+\.\d+\.\d+-alpine$'';
              "wud.tag.transform" = ''^(\d+\.\d+\.\d+)-alpine$ => $1'';
            };
            networks = [privateNetwork];
            volumes = [
              "${configurationDirectory}/redis:/data"
            ];
            cmd = ["redis-server"];
          };

          ${name} = mkMerge [
            (mkContainer {
              inherit name cfg config;
              image = "outlinewiki/outline:1.9.2";
              serviceName = "wiki";
              servicePort = 3000;
              homepage = {
                group = "Services";
                name = "Outline";
                icon = "outline.png";
                description = "Team knowledge base";
                serviceName = "wiki";
              };
            })
            {
              dependsOn = [postgresName redisName];
              environment = {
                NODE_ENV = "production";
                PORT = "3000";
                URL = "https://${serviceHostname}.xerus-augmented.ts.net";
                PGSSLMODE = "disable";
                FILE_STORAGE = "local";
                FILE_STORAGE_LOCAL_ROOT_DIR = "/var/lib/outline/data";
                FORCE_HTTPS = "true";
                ENABLE_UPDATES = "false";
                LOG_LEVEL = "info";
              };
              environmentFiles = [
                config.sops.templates."hosting/services/outline.env".path
              ];
              networks = [privateNetwork];
              volumes = [
                "${configurationDirectory}/data:/var/lib/outline/data"
              ];
            }
          ];
        };
      }
    ]);
  }
