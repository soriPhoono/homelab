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
    options.hosting.services.portainer =
      (mkContainerOption {
        inherit name;
        description = "A container management platform";
      })
      // {
        edgeId = mkOption {
          type = types.str;
          description = "The ID of the edge device";
        };
      };

    config = mkIf cfg.enable (mkMerge [
      {
        hosting.enable = true;

        sops = {
          secrets = {
            portainer-edge-key = {};
          };

          templates = {
            "hosting/services/portainer.env".content = ''
              EDGE_ID=${cfg.edgeId}
              EDGE_KEY=${sops.secrets.portainer-edge-key.placeholder}
            '';
          };
        };

        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        virtualisation.oci-containers.containers = {
          # portainer-agent = {
          #   image = "docker.io/portainer/agent:2.39.5";
          #   environment = {
          #     EDGE = "1";
          #     EDGE_INSECURE_POLL = "1";
          #     EDGE_ASYNC = "1";
          #   };
          #   environmentFiles = [
          #     config.sops.templates."hosting/services/portainer.env".path
          #   ];
          #   volumes = [
          #     "portainer_agent_data:/data"
          #     "/:/host:ro"
          #     "/var/run/docker.sock:/var/run/docker.sock"
          #     "/var/lib/docker/volumes:/var/lib/docker/volumes"
          #   ];
          # };
          ${name} = mkMerge [
            (mkContainer {
              inherit name cfg config;
              image = "portainer/portainer-ee:2.45.0";
              serviceName = "admin";
              servicePort = 9000;
              homepage = {
                group = "Services";
                name = "Portainer";
                icon = "portainer.png";
                description = "Container management";
                serviceName = "admin";
              };
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
        };
      }
    ]);
  }
