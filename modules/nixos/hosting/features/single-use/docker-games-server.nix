{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.hosting.features.single-use.docker-games-server;
in
  with lib; {
    options.hosting.features.single-use.docker-games-server = {
      enable = mkEnableOption "Enable self-hosted game streaming server";

      gpuRenderNode = mkOption {
        type = types.str;
        default = "/dev/dri/renderD128";
        description = "The node to render gstreamer frames (must be the same gpu that's running the game)";
        example = "/dev/dri/renderD129";
      };
      openFirewall = mkEnableOption "Enable modifications to firewall for server port exposure";

      dataDir = mkOption {
        type = types.str;
        default = "~/Documents/Games";
        description = "The location for the game server's data";
        example = "/mnt/games";
      };
    };

    config = mkIf cfg.enable {
      hosting.backends.podman.enable = true;

      networking.firewall = mkIf cfg.openFirewall {
        allowedTCPPorts = [48010 47989 47984];
        allowedUDPPorts = [47999 48100 48200];
      };

      systemd.services.run-gow = {
        description = "Launch games-on-whales";
        after = ["network-online.target" "podman.service"];
        wants = ["network-online.target"];
        wantedBy = ["multi-user.target"];
        script = "${pkgs.writeShellApplication {
          name = "run-gow.sh";
          runtimeInputs = with pkgs; [
            sudo
            curl

            podman
          ];
          text = ''
            if [[ ! -f ${cfg.gpuRenderNode} ]]; then exit 1; fi

            NODE="$(basename ${cfg.gpuRenderNode})"
            case $(cat /sys/class/drm/"$NODE"/device/vendor) in
              "nvidia")
                sudo curl https://raw.githubusercontent.com/games-on-whales/gow/master/images/nvidia-driver/Dockerfile \
                  | sudo podman build -t gow/nvidia-driver:latest -f - --build-arg NV_VERSION="$(cat /sys/module/nvidia/version)" .
                sudo podman run --rm \
                  --mount source=nvidia-driver-vol,destination=/usr/nvidia \
                  gow/nvidia-driver:latest true
                sudo podman run --rm \
                  --mount source=nvidia-driver-vol,destination=/usr/nvidia \
                  --device /dev/dri \
                  --device /dev/uinput \
                  --device /dev/uhid \
                  --device /dev/nvidia-uvm \
                  --device /dev/nvidia-uvm-tools \
                  --device /dev/nvidia-caps/nvidia-cap1 \
                  --device /dev/nvidia-caps/nvidia-cap2 \
                  --device /dev/nvidiactl \
                  --device /dev/nvidia0 \
                  --device /dev/nvidia-modeset \
                  -v ${cfg.dataDir}:/etc/wolf \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v /dev:/dev \
                  -v /run/udev:/run/udev \
                  -e WOLF_STOP_CONTAINER_ON_EXIT=TRUE \
                  -e NVIDIA_DRIVER_VOLUME_NAME=nvidia-driver-vol \
                  -e WOLF_RENDER_NODE=${cfg.gpuRenderNode} \
                  -p 47984:47984/tcp \
                  -p 47989:47989/tcp \
                  -p 48010:48010/tcp \
                  -p 47999:47999/udp \
                  -p 48100:48100/udp \
                  -p 48200:48200/udp \
                  --security-opt label=disable \
                  --device-cgroup-rule=c 13:* rmw \
                  ghcr.io/games-on-whales/wolf:stable
                ;;
              "amd"|"intel")
                sudo podman run --rm \
                  --device /dev/dri \
                  --device /dev/uinput \
                  --device /dev/uhid \
                  -v ${cfg.dataDir}:/etc/wolf \
                  -v /var/run/docker.sock:/var/run/docker.sock \
                  -v /dev:/dev \
                  -v /run/udev:/run/udev \
                  -e WOLF_STOP_CONTAINER_ON_EXIT=TRUE \
                  -e WOLF_RENDER_NODE=${cfg.gpuRenderNode} \
                  -p 47984:47984/tcp \
                  -p 47989:47989/tcp \
                  -p 48010:48010/tcp \
                  -p 47999:47999/udp \
                  -p 48100:48100/udp \
                  -p 48200:48200/udp \
                  --security-opt label=disable \
                  --device-cgroup-rule=c 13:* rmw \
                  ghcr.io/games-on-whales/wolf:stable
                ;;
              *)
                echo "Failed to identify provided render node to create service container"
                exit 1
                ;;
            esac
          '';
        }}/bin/run-gow.sh";
      };
    };
  }
