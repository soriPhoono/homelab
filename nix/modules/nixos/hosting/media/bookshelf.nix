{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  cfg = config.hosting.media.bookshelf;

  name = "bookshelf";
  configurationDirectory = "/var/lib/bookshelf";
in
  with lib; {
    options.hosting.media.bookshelf = mkContainerOption {
      inherit name;
      description = "The E-Book requester engine";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.bookshelf = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "ghcr.io/pennydreadful/bookshelf:hardcover";
            serviceName = "books";
            servicePort = 8787;
          })
          {
            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/books:/books"
              "/mnt/local/media/downloads:/downloads"
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
