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
        hosting.enable = true;

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "hkotel/mealie:v3.24.0";
            serviceName = "cookbook";
            servicePort = 9000;
            homepage = {
              group = "Services";
              name = "Mealie";
              icon = "mealie.png";
              description = "Recipe and meal planning";
              serviceName = "cookbook";
            };
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
