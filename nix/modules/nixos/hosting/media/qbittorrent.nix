{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.media.qbittorrent;

  name = "qbittorrent";
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.qbittorrent = mkContainerOption {
      inherit name;
      description = "A torrent download manager";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.qbittorrent = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/qbittorrent:5.2.3";
            subdomain = "downloads";
            port = 8080;
            publish = true;
          })
          {
            environment = {
              PUID = "0";
              PGID = "0";
              WEBUI_PORT = "8080";
              TORRENTING_PORT = "6881";
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/downloads:/downloads"
            ];
          }
        ];
      }
    ]);
  }
