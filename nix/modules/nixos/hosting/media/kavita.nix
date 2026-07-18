{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer mkContainerOption;

  name = "kavita";
  cfg = config.hosting.media.${name};
  configurationDirectory = "/var/lib/${name}";
in
  with lib; {
    options.hosting.media.${name} = mkContainerOption {
      inherit name;
      description = "The digital library (comics and manga) reader";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 microserver microserver -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "linuxserver/kavita:latest";
            serviceName = "library";
            servicePort = 5000;
          })
          {
            environment = {
              PUID = toString config.users.users.microserver.uid;
              PGID = toString config.users.groups.microserver.gid;
              TZ = config.time.timeZone;
            };

            volumes = [
              "${configurationDirectory}:/config"
              "/mnt/local/media/books:/library"
            ];
          }
        ];
      }
    ]);
  }
