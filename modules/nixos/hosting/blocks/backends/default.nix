{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.blocks.backends;
in
  with lib; {
    imports = [
      ./management
    ];

    options.hosting.blocks.backends = {
      type = mkOption {
        type = types.enum ["docker" "podman"];
        default = "podman";
        description = "The container engine to use for hosting blocks.";
        example = "docker";
      };

      nvidiaSupport = mkEnableOption "NVIDIA support for hosting blocks.";
    };

    config = mkIf config.hosting.enable (mkMerge [
      (let
        invocation =
          if cfg.type == "docker"
          then pkgs.docker
          else pkgs.podman;
        serviceName = "${cfg.type}-create-networks";
      in {
        systemd.services =
          {
            "${serviceName}" = let
              networks = unique (
                flatten (mapAttrsToList (_: c: c.networks or []) config.virtualisation.oci-containers.containers)
              );
            in {
              after = ["${cfg.type}.service"];
              wantedBy = ["multi-user.target"];
              serviceConfig = {
                Type = "oneshot";
                ExecStart = "${pkgs.writeShellScriptBin "${serviceName}" ''
                  ${lib.optionalString (networks != []) ''
                    EXISTING_NETWORKS=$(${invocation}/bin/${cfg.type} network ls --format '{{.Name}}')
                    ${lib.concatStringsSep "\n" (map (network: ''
                        if ! printf '%s\n' "$EXISTING_NETWORKS" | grep -Fxq "${network}"; then
                          ${invocation}/bin/${cfg.type} network create "${network}"
                        fi
                      '')
                      networks)}
                  ''}
                ''}/bin/${serviceName}";
              };
            };
          }
          // (lib.listToAttrs (lib.mapAttrsToList (name: _: {
              name = "${cfg.type}-${name}";
              value = {
                after = ["${serviceName}.service"];
                bindsTo = ["${serviceName}.service"];
              };
            })
            config.virtualisation.oci-containers.containers));
      })
      (mkIf (cfg.type == "docker") {
        virtualisation.docker = {
          enable = true;
          autoPrune.enable = true;
        };

        users.extraUsers =
          lib.mapAttrs (_name: _user: {
            extraGroups = ["docker"];
          })
          (lib.filterAttrs (_name: user: user.admin) config.core.users);
      })
      (mkIf (cfg.type == "podman") {
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
      })
    ]);
  }
