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
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/lidarr:latest";
            serviceName = "music";
            servicePort = 8686;
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
