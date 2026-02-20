{
  pkgs,
  lib,
  ...
}: let
  # Create a minimal NixOS configuration
  eval = lib.nixosSystem {
    inherit pkgs;
    modules = [
      {
        imports = [
          ../modules/nixos/hosting/blocks/backends/management/default.nix
        ];

        # Stub for options defined in backends/default.nix
        options.hosting.blocks.backends.type = lib.mkOption {
          type = lib.types.enum ["docker" "podman"];
          default = "podman";
        };

        # Stub for virtualisation options since we don't import full NixOS
        options.virtualisation.oci-containers.containers = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = {};
        };

        config = {
          hosting.blocks.backends.management.type = "portainer";
          hosting.blocks.backends.management.portainer.mode = "edge-agent";
          hosting.blocks.backends.type = "docker";
        };
      }
    ];
  };

  # Extract the volumes
  volumes = eval.config.virtualisation.oci-containers.containers.admin_portainer-agent.volumes;

  # Check if vulnerable mount exists
  hasVulnerableMount = builtins.elem "/:/host" volumes;

in
  pkgs.runCommand "test-portainer-security" {} ''
    if [ "${toString hasVulnerableMount}" = "1" ]; then
      echo "VULNERABILITY DETECTED: /:/host mount found in portainer edge-agent configuration"
      exit 1
    else
      echo "Secure: /:/host mount not found"
      touch $out
    fi
  ''
