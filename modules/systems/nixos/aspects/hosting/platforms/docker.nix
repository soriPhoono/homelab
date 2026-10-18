/**
  Rootful Docker for containers shared by every user of the host.

  Kept a plain set so swarm clustering can return later as a sub-aspect
  (`den.aspects.hosting.docker.swarm`) without touching hosts that only need
  the runtime.
*/
{
  den.aspects.hosting.docker = {
    nixos =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      {
        imports = [
          ./_private/tailscale-bypass.nix
        ];

        virtualisation = {
          oci-containers.backend = "docker";
          docker = {
            enable = true;
            autoPrune.enable = true;
            # Containers resolve through public DNS rather than the host's
            # Tailscale-managed resolv.conf, which breaks under MagicDNS.
            daemon.settings.dns = [
              "1.1.1.1"
              "1.0.0.1"
            ];
          };
        };

        # Docker group membership is root-equivalent: admins only.
        users.groups.docker.members = config.users.groups.wheel.members;

        systemd.services = {
          # Create every network named by an oci-container before it starts.
          docker-create-networks =
            let
              networks = lib.unique (
                lib.concatMap (c: c.networks or [ ]) (
                  lib.attrValues config.virtualisation.oci-containers.containers
                )
              );
            in
            {
              after = [ "docker.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                ExecStart = lib.getExe (
                  pkgs.writeShellApplication {
                    name = "docker-create-networks";
                    runtimeInputs = [
                      config.virtualisation.docker.package
                      pkgs.gnugrep
                    ];
                    text = lib.optionalString (networks != [ ]) ''
                      EXISTING_NETWORKS=$(docker network ls --format '{{.Name}}')
                      ${lib.concatMapStringsSep "\n" (network: ''
                        if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                          docker network create "${network}"
                        fi
                      '') networks}
                    '';
                  }
                );
              };
            };
        }
        // lib.mapAttrs' (
          name: _:
          lib.nameValuePair "docker-${name}" {
            after = [ "docker-create-networks.service" ];
            bindsTo = [ "docker-create-networks.service" ];
          }
        ) config.virtualisation.oci-containers.containers;
      };

    # Projected onto users by host-aspects; only admins can reach the socket.
    homeManager =
      {
        lib,
        config,
        osConfig,
        ...
      }:
      {
        programs.lazydocker.enable = lib.elem config.home.username osConfig.users.groups.wheel.members;
      };
  };
}
