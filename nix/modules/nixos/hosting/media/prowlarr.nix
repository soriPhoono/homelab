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
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/prowlarr:2.4.0";
            subdomain = "indexers";
            port = "9696";
            publish = true;
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
