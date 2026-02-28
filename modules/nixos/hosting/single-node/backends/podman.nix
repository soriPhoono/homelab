{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.single-node.backends.podman;
in
  with lib; {
    options.hosting.single-node.backends.podman = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Enable podman backend";
      };
    };

    config = mkIf cfg.enable (let
      invocation = pkgs.docker;
      networkServiceName = "docker-create-networks";
    in {
      assertions = [
        {
          assertion = !config.hosting.single-node.backends.docker.enable;
          message = "Cannot enable both docker and podman backends";
        }
      ];

      systemd.services =
        {
          "${networkServiceName}" = let
            networks = unique (
              flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
            );
          in {
            after = ["docker.service"];
            wantedBy = ["multi-user.target"];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${pkgs.writeShellScriptBin "${networkServiceName}" ''
                ${lib.optionalString (networks != []) ''
                  EXISTING_NETWORKS=$(${invocation}/bin/docker network ls --format '{{.Name}}')
                  ${lib.concatStringsSep "\n" (lib.map (network: ''
                      if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                        ${invocation}/bin/docker network create "${network}"
                      fi
                    '')
                    networks)}
                ''}
              ''}/bin/${networkServiceName}";
            };
          };
        }
        // (lib.listToAttrs (lib.mapAttrsToList (name: _: {
            name = "docker-${name}";
            value = {
              after = ["${networkServiceName}.service" "${pluginServiceName}.service"];
              bindsTo = ["${networkServiceName}.service" "${pluginServiceName}.service"];
            };
          })
          config.virtualisation.oci-containers.containers));

      virtualisation.podman = {
        enable = true;
        dockerSocket.enable = true;
        dockerCompat = true;
        autoPrune = {
          enable = true;
          dates = "daily";
          flags = [
            "--all"
          ];
        };
      };

      home-manager.users =
        lib.mapAttrs (_name: _value: {
          services.podman.enable = true;
        })
        config.core.users;
    });
  }
