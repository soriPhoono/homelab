{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.media.prowlarr;

  name = "prowlarr";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.prowlarr = mkContainerOption {
      inherit name;
      description = "The indexer aggregator engine";
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
            image = "linuxserver/prowlarr:2.5.2";
            serviceName = "indexers";
            servicePort = 9696;
            homepage = {
              group = "Media";
              name = "Prowlarr";
              icon = "prowlarr.png";
              description = "Indexer aggregator";
              serviceName = "indexers";
            };
          })
          {
            volumes = [
              "${configurationDirectory}:/config"
            ];

            environment = {
              PUID = "0";
              PGID = "0";
              TZ = config.time.timeZone;
            };
          }
        ];
      }
    ]);
  }
