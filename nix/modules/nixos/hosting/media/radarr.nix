{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.media.radarr;

  name = "radarr";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The movie aggregator engine";
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
            image = "linuxserver/radarr:6.3.0";
            serviceName = "movies";
            servicePort = 7878;
            homepage = {
              group = "Media";
              name = "Radarr";
              icon = "radarr.png";
              description = "Movie manager";
              serviceName = "movies";
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
              "/mnt/local/media/movies:/movies"
              "/mnt/local/media/downloads:/downloads"
            ];
          }
        ];
      }
    ]);
  }
