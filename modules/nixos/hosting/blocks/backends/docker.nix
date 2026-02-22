{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.blocks.backends.docker;
in
  with lib; {
    options.hosting.blocks.backends.docker = {
      enable = mkEnableOption "docker backend";

      extraSettings = mkOption {
        type = types.attrsOf types.any;
        default = {};
        description = "Extra settings for docker backend";
      };
    };

    config = let
      invocation = pkgs.docker;
      serviceName = "docker-create-networks";
    in
      mkIf cfg.enable {
        systemd.services =
          {
            "${serviceName}" = let
              networks = unique (
                flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
              );
            in {
              after = ["docker.service"];
              wantedBy = ["multi-user.target"];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.writeShellScriptBin "${serviceName}" ''
                  ${lib.optionalString (networks != []) ''
                    EXISTING_NETWORKS=$(${invocation}/bin/docker network ls --format '{{.Name}}')
                    ${lib.concatStringsSep "\n" (lib.map (network: ''
                        if ! echo "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                          ${invocation}/bin/docker network create "${network}"
                        fi
                      '')
                      networks)}
                  ''}
                ''}/bin/${serviceName}";
              };
            };
          }
          // (lib.listToAttrs (lib.mapAttrsToList (name: _: {
              name = "docker-${name}";
              value = {
                after = ["${serviceName}.service"];
                bindsTo = ["${serviceName}.service"];
              };
            })
            config.virtualisation.oci-containers.containers));

        virtualisation.docker = {
          enable = true;
          autoPrune.enable = true;
          daemon.settings = cfg.extraSettings;
        };

        users.extraUsers =
          lib.mapAttrs (_name: _user: {
            extraGroups = ["docker"];
          })
          (lib.filterAttrs (_name: user: user.admin) config.core.users);
      };
  }
