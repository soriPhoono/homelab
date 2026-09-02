{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "navidrome";
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
            image = "deluan/navidrome:0.63.2";
            serviceName = "jukebox";
            servicePort = 4533;
            homepage = {
              group = "Media";
              name = "Navidrome";
              icon = "navidrome.png";
              description = "Music streaming server";
              serviceName = "jukebox";
            };
          })
          {
            user = "0:0";
            volumes = [
              "${configurationDirectory}:/data"
              "/mnt/local/media/music:/music"
            ];
          }
        ];
      }
    ]);
  }
