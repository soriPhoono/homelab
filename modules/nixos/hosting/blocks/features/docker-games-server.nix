{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.blocks.features.docker-games-server;

  # Determine hosting backend
  backend = config.hosting.blocks.backends.type;
  isPodman = backend == "podman";
  socketPath =
    if isPodman
    then "/run/podman/podman.sock"
    else "/var/run/docker.sock";
  containerCmd =
    if isPodman
    then "podman"
    else "docker";

  launcherScript = pkgs.writeShellApplication {
    name = "wolf-launcher";
    runtimeInputs = with pkgs; [
      curl
      (
        if isPodman
        then podman
        else docker
      )
      coreutils
      gawk
      gnused
    ];
    text = ''
      RENDER_NODE="${cfg.gpuRenderNode}"
      if [[ ! -e "$RENDER_NODE" ]]; then
        echo "Error: GPU render node $RENDER_NODE not found."
        exit 1
      fi

      NODE_NAME=$(basename "$RENDER_NODE")
      VENDOR_ID=$(cat "/sys/class/drm/$NODE_NAME/device/vendor")

      # Common arguments
      ARGS=(
        run --name wolf
        -v "${cfg.dataDir}:/etc/wolf"
        -v "${socketPath}:/var/run/docker.sock"
        -v /dev:/dev:rw
        -v /run/udev:/run/udev:rw
        -p 47984:47984/tcp -p 47989:47989/tcp -p 48010:48010/tcp
        -p 47999:47999/udp -p 48100:48100/udp -p 48200:48200/udp
        --device-cgroup-rule='c 13:* rmw'
        --device-cgroup-rule='c 226:* rmw'
        --device /dev/uinput
        --device /dev/uhid
        --device /dev/dri
        -e WOLF_STOP_CONTAINER_ON_EXIT=TRUE
        -e WOLF_RENDER_NODE="$RENDER_NODE"
      )

      if [[ "$VENDOR_ID" == "0x10de" ]]; then
        echo "Detected Nvidia GPU on $RENDER_NODE"

        # Check if we are running podman or docker and apply correct flags
        ${
        if isPodman
        then ''
          ARGS+=(
              --device nvidia.com/gpu=all
              --security-opt=label=disable
              -e NVIDIA_DRIVER_CAPABILITIES=all
              -e NVIDIA_VISIBLE_DEVICES=all
          )
        ''
        else ''
          ARGS+=(
              --gpus all
          )
        ''
      }
      else
        echo "Detected AMD/Intel GPU on $RENDER_NODE (Vendor: $VENDOR_ID)"
      fi

      echo "Starting Wolf container..."
      exec ${containerCmd} "''${ARGS[@]}" ghcr.io/games-on-whales/wolf:stable
    '';
  };
in
  with lib; {
    options.hosting.blocks.features.docker-games-server = {
      enable = mkEnableOption "Enable self-hosted game streaming server";
      openFirewall = mkEnableOption "Enable modifications to firewall for server port exposure";

      dataDir = mkOption {
        type = types.str;
        default = "/etc/wolf";
        description = "The location for the game server's data/config";
      };

      gpuRenderNode = mkOption {
        type = types.str;
        default = "/dev/dri/renderD128";
        description = "The path to the GPU render node (e.g., /dev/dri/renderD128)";
      };
    };

    config = mkIf cfg.enable {
      hosting.enable = true;

      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [48010 47989 47984];
        allowedUDPPorts = [47999 48100 48200];
      };

      systemd.services.wolf = {
        description = "Games on Whales (Wolf) Service";
        after = ["network-online.target" "${backend}.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];

        serviceConfig = {
          Restart = "no";
          ExecStartPre = [
            "${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDir}"
          ];
          ExecStart = "${launcherScript}/bin/wolf-launcher";
        };
      };
    };
  }
