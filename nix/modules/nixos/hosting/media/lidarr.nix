{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "lidarr";
  cfg = config.hosting.media.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The music requester engine";
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
            image = "linuxserver/lidarr:3.1.0";
            serviceName = "music";
            servicePort = 8686;
            homepage = {
              group = "Media";
              name = "Lidarr";
              icon = "lidarr.png";
              description = "Music manager";
              serviceName = "music";
            };
          })
          {
            environment = {
              PUID = "0";
              PGID = "0";
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/music:/music"
              "/mnt/local/media/downloads:/downloads"
            ];
          }
        ];
      }
    ]);
  }
