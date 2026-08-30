{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "vikunja";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Personal task and project management application";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        sops.secrets."api/vikunja-service-secret" = {};

        sops.templates."hosting/services/vikunja.env".content = ''
          VIKUNJA_SERVICE_SECRET=${config.sops.placeholder."api/vikunja-service-secret"}
        '';

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
          "d ${configurationDirectory}/db 0700 1000 1000 -"
          "d ${configurationDirectory}/files 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "vikunja/vikunja:latest";
            serviceName = "tasks";
            servicePort = 3456;
          })
          {
            environment = {
              VIKUNJA_DATABASE_PATH = "/db/vikunja.db";
              VIKUNJA_DATABASE_TYPE = "sqlite";
              VIKUNJA_FILES_BASEPATH = "/app/vikunja/files";
              VIKUNJA_SERVICE_TIMEZONE = config.time.timeZone;
            };
            environmentFiles = [
              config.sops.templates."hosting/services/vikunja.env".path
            ];
            volumes = [
              "${configurationDirectory}/db:/db"
              "${configurationDirectory}/files:/app/vikunja/files"
            ];
          }
        ];
      }
    ]);
  }
