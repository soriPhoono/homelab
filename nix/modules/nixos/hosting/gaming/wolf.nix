# TODO: Add NVIDIA support
# TODO: Refactor this into a rootful container for cgroup support, will require expanding the mkContainer function to support rootful containers
{
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib.homelab.containers) mkContainer;

  cfg = config.hosting.gaming.${name};

  name = "wolf";
  configurationDirectory = "/var/lib/${name}";

  gpuDevices =
    if cfg.gpu == "integrated"
    then {
      render = "/dev/dri/renderD128";
      card = "/dev/dri/card1";
    }
    else if cfg.gpu == "mesa-compatible"
    then {
      render = "/dev/dri/renderD129";
      card = "/dev/dri/card2";
    }
    else if cfg.gpu == "NVIDIA"
    then throw "TODO: Create nvidia gpu module support"
    else throw "No gpu selected";
in
  with lib; {
    options.hosting.gaming.${name} = {
      enable = mkEnableOption "Enable Games on Whales (Wolf) game streaming server";

      gpu = mkOption {
        type = types.enum ["integrated" "mesa-compatible" "NVIDIA"];
        default = null;
        description = ''
          GPU to pass through for game rendering and encoding.

          - `"integrated"`: pass only the integrated GPU (`/dev/dri/renderD128` + `/dev/dri/card1`).
          - `"mesa-compatible"`: pass only the dedicated GPU (`/dev/dri/renderD129` + `/dev/dri/card2`).
          - `"NVIDIA"`: TODO, create a dedicated option for nvidia gpu pass through.
        '';
      };

      internalMac = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          MAC address of the host's LAN interface for Wolf to use as its own.
          Required when running over Tailscale — the tailscale0 interface has
          NOARP and no MAC address, causing Wolf to fail with:
          "Unable to get mac address of ip address: <tailscale-ip>"

          Set this to the MAC address of the physical NIC (e.g. enp6s0).
          Find it with: ip link show <interface> | grep -o 'ether [0-9a-f:]*'
        '';
        example = "c2:d8:de:57:c6:7c";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${configurationDirectory} 0755 root root -"
        ];

        # Ensure /dev/uinput exists and is accessible
        # This is needed for virtual input device creation
        services.udev.extraRules = ''
          KERNEL=="uinput", MODE="0660", GROUP="input"
          KERNEL=="uhid", MODE="0660", GROUP="input"
        '';

        users.users.microserver.extraGroups = [
          "input"
          "render"
          "video"
        ];

        systemd.services.podman-wolf.preStart = ''
          ${pkgs.podman}/bin/podman rm --force WolfPulseAudio
        '';

        # Wolf container via OCI module
        virtualisation.oci-containers.containers.${name} = mkMerge [
          (mkContainer {
            inherit name cfg config;
            image = "ghcr.io/games-on-whales/wolf:stable";
            root = true;
          })
          {
            volumes = [
              "${configurationDirectory}:/etc/wolf:rw"
              "/var/run/docker.sock:/var/run/docker.sock:rw"
              "/run/udev:/run/udev:rw"
              "/dev:/dev:rw"
            ];

            environment = {
              WOLF_LOG_LEVEL = "INFO";
              WOLF_STOP_CONTAINER_ON_EXIT = "TRUE";
              WOLF_INTERNAL_MAC = cfg.internalMac;
              WOLF_RENDER_NODE = gpuDevices.render;
            };

            extraOptions = [
              "--network=host"
              "--init"
              "--device=/dev/uinput"
              "--device=/dev/uhid"
              "--device-cgroup-rule=c 13:* rmw"
              "--device=${gpuDevices.render}"
              "--device=${gpuDevices.card}"
            ];
          }
        ];

        networking.firewall = {
          allowedTCPPorts = [
            47984
            47989
            47990
            48010
          ];

          allowedUDPPorts = [
            47998
            47999
            48002
            48010
            48100
            48200
          ];
        };
      }
    ]);
  }
