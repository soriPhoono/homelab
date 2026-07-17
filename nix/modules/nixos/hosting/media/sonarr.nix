{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.media.sonarr;

  name = "sonarr";
  configurationDirectory = "/var/lib/sonarr";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The TV show aggregator engine";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/sonarr:4.0.19";
            subdomain = "shows";
            port = 8989;
            publish = true;
          })
          {
            environment = {
              PUID = "0";
              PGID = "0";
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/shows:/tv"
              "/mnt/local/media/downloads:/downloads"
            ];
          }
        ];
      }
    ]);
  }
