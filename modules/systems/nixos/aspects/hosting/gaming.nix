/**
  Game streaming: a Wolf (Games on Whales) server on the hosting machine and
  a Moonlight client on the receiving one.
*/
{ den, ... }:
{
  den.aspects.hosting.gaming = {
    # Registers the parent so its sub-aspects resolve.
    nixos = _: { };

    host = {
      includes = [
        den.aspects.hosting.docker
      ];

      nixos =
        {
          lib,
          config,
          ...
        }:
        let
          cfg = config.hosting.gaming.wolf;
          inherit (cfg) renderDevice cardDevice internalMac;
          stateDirectory = "/var/lib/wolf";
          nvidia = renderDevice == null;
        in
        {
          options.hosting.gaming.wolf = {
            renderDevice = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/dev/dri/renderD129";
              description = ''
                Render node Wolf uses for game rendering and encoding. Set
                together with `cardDevice`; leave both null to fall back to
                the NVIDIA container toolkit.
              '';
            };

            cardDevice = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "/dev/dri/card1";
              description = ''
                Card node passed to Wolf. Set together with `renderDevice`;
                leave both null to fall back to the NVIDIA container toolkit.
              '';
            };

            internalMac = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              example = "c2:d8:de:57:c6:7c";
              description = ''
                MAC address of the host's LAN interface for Wolf to use as its
                own. Required when running over Tailscale — the tailscale0
                interface has NOARP and no MAC address, causing Wolf to fail
                with: "Unable to get mac address of ip address: <tailscale-ip>"

                Find it with: ip link show <interface> | grep -o 'ether [0-9a-f:]*'
              '';
            };
          };

          config = lib.mkMerge [
            {
              assertions = [
                {
                  assertion = (renderDevice == null) == (cardDevice == null);
                  message = "hosting.gaming.wolf: set both renderDevice and cardDevice, or neither to use the NVIDIA container toolkit.";
                }
              ];

              systemd.tmpfiles.rules = [
                "d ${stateDirectory} 0755 root root -"
              ];

              # Virtual input devices for streamed controllers and keyboards.
              services.udev.extraRules = ''
                KERNEL=="uinput", MODE="0660", GROUP="input"
                KERNEL=="uhid", MODE="0660", GROUP="input"
              '';

              # Wolf leaves its PulseAudio sidecar behind on exit, which then
              # blocks the next start.
              systemd.services."docker-wolf".preStart = ''
                ${lib.getExe config.virtualisation.docker.package} rm --force WolfPulseAudio
              '';

              virtualisation.oci-containers.containers.wolf = {
                # Docker Hub publishes Wolf only as the mutable stable tag;
                # the digest pins the exact build.
                image = "gameonwhales/wolf:stable@sha256:0d901e766e6ed288712ff994dd3b877aea7c9f22ff6e5b0efbb16bc7bb4ae9a4";
                volumes = [
                  "${stateDirectory}:/etc/wolf:rw"
                  "/var/run/docker.sock:/var/run/docker.sock:rw"
                  "/run/udev:/run/udev:rw"
                  "/dev:/dev:rw"
                ];
                environment = {
                  WOLF_LOG_LEVEL = "INFO";
                  WOLF_STOP_CONTAINER_ON_EXIT = "TRUE";
                }
                // lib.optionalAttrs (internalMac != null) {
                  WOLF_INTERNAL_MAC = internalMac;
                }
                // lib.optionalAttrs (!nvidia) {
                  WOLF_RENDER_NODE = renderDevice;
                };
                extraOptions = [
                  "--network=host"
                  "--init"
                  "--device=/dev/uinput"
                  "--device=/dev/uhid"
                  "--device-cgroup-rule=c 13:* rmw"
                ]
                ++ (
                  if nvidia then
                    [ "--device=nvidia.com/gpu=all" ]
                  else
                    [
                      "--device=${renderDevice}"
                      "--device=${cardDevice}"
                    ]
                );
              };

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

            # TODO: Wolf's nvidia-container-toolkit support is still maturing;
            # this CDI fallback is untested and the render node is left for
            # Wolf to discover. The toolkit module asserts the driver is present.
            (lib.mkIf nvidia {
              hardware.nvidia-container-toolkit.enable = true;
            })
          ];
        };
    };

    # User aspect: include on `<user>@<host>` for each receiving machine.
    client = {
      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.moonlight-qt ];
        };
    };
  };
}
