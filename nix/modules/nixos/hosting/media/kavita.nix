{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "kavita";
  cfg = config.hosting.media.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The digital library (comics and manga) reader";
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
            image = "linuxserver/kavita:0.9.1";
            serviceName = "library";
            servicePort = 5000;
            homepage = {
              group = "Media";
              name = "Kavita";
              icon = "kavita.png";
              description = "Digital library reader";
              serviceName = "library";
            };
          })
          {
            environment = {
              PUID = "1000";
              PGID = "1000";
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/books:/library"
            ];
          }
        ];
      }
    ]);
  }
