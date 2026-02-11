{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.blocks.backends.management.portainer;
in
  with lib; {
    options.hosting.blocks.backends.management.portainer = {
      mode = mkOption {
        type = with types; enum ["server" "agent" "edge-agent" "edge-agent-async"];
        default = "agent";
        description = "The mode to deploy portainer agent/edge-agent, and a possible portainer server";
        example = "server";
      };
    };

    # Note, check when it comes time to use edge-agent variants
    config =
      mkIf (config.hosting.blocks.backends.management.type == "portainer")
      {
        virtualisation.oci-containers.containers = {
          admin_portainer-agent = mkMerge [
            {
              image = "portainer/agent:lts";
              volumes = [
                "${
                  if config.hosting.blocks.backends.type == "podman"
                  then "/run/podman/podman.sock"
                  else "/var/run/docker.sock"
                }:/var/run/docker.sock"
              ];
              networks = ["admin_portainer-agent"];
            }
            (mkIf (builtins.elem cfg.mode ["edge-agent" "edge-agent-async"]) {
              volumes = [
                "/var/lib/docker/volumes:/var/lib/docker/volumes"
                "/:/host"
              ];
              environment = {
                EDGE = "1";
                EDGE_ID = "";
                EDGE_KEY = "";
                EDGE_INSECURE_POLL = "0";
              };
            })
          ];

          admin_portainer-server = mkIf (cfg.mode == "server") {
            image = "portainer/portainer-ee:latest";
            dependsOn = ["admin_portainer-agent"];
            cmd = ["-H" "tcp://admin_portainer-agent:9001" "--tlsskipverify"];
            volumes = ["admin_portainer-data:/data"];
            networks = ["admin_portainer-agent" "admin_traefik-public"];
          };
        };
      };
  }
