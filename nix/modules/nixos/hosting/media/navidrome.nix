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
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;

            image = "deluan/navidrome:0.63.2";
            subdomain = "jukebox";
            port = 4533;
            publish = true;
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
