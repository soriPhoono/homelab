# NOTE: Separate the agent from the server when creating the master cluster to control and administer configuration to edge devices
{
  lib,
  config,
  ...
}: let
  inherit (lib.homelab.containers) mkContainerOption mkContainer;

  cfg = config.hosting.services.portainer;

  name = "portainer";
  configurationDirectory = "/var/lib/portainer";
in
  with lib; {
    options.hosting.services.portainer = mkContainerOption {
      inherit name;
      description = "A container management platform";
    };

    config = mkIf cfg.enable (mkMerge [
      {
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "docker.io/portainer/portainer-ee:lts";
            serviceName = "admin";
            servicePort = 9000;
          })
          {
            volumes = [
              "/var/run/docker.sock:/var/run/docker.sock"
              "${configurationDirectory}:/data"
            ];

            ports = [
              "8000:8000"
            ];
          }
        ];
      }
    ]);
  }
