{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "grocy";
  cfg = config.hosting.services.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.services.${name} = mkContainerOption {
      inherit name;
      description = "Household grocery, pantry, and chore management";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0750 1000 1000 -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "lscr.io/linuxserver/grocy:latest";
            serviceName = "groceries";
            servicePort = 80;
          })
          {
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = config.time.timeZone;
            };
            volumes = [
              "${configurationDirectory}:/config"
            ];
          }
        ];
      }
    ]);
  }
