{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "mealie";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Recipe and meal planning application";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "ghcr.io/mealie-recipes/mealie:latest";
            serviceName = "cookbook";
            servicePort = 9000;
          })
          {
            environment = {
              ALLOW_SIGNUP = "false";
              DB_ENGINE = "sqlite";
              PGID = "1000";
              PUID = "1000";
              TZ = config.time.timeZone;
            };
            volumes = [
              "${configurationDirectory}:/app/data"
            ];
          }
        ];
      }
    ]);
  }
