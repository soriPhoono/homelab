{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.media.seerr;

  name = "seerr";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The media request engine";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "seerr/seerr:v3.4.1";
            serviceName = "pvr";
            servicePort = 5055;
            homepage = {
              group = "Media";
              name = "Seerr";
              icon = "seerr.png";
              description = "Media request manager";
              serviceName = "pvr";
            };
          })
          {
            user = "0:0";
            environment = {
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/app/config:rw"
            ];
          }
        ];
      }
    ]);
  }
