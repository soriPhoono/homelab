{
  lib,
  config,
  ...
}: let
  cfg = config.hosting.gaming.wolf;
  inherit (cfg) gpu;

  # GPU device paths — these are the DRM render + primary nodes.
  # On most multi-GPU Linux systems, renderD128 is the integrated GPU
  # and renderD129+ are dedicated GPUs. Adjust here if needed.
  gpuDevices = {
    integrated = {
      render = "/dev/dri/renderD128";
      card = "/dev/dri/card1";
    };
    dedicated = {
      render = "/dev/dri/renderD129";
      card = "/dev/dri/card2";
    };
  };

  selectedGpu =
    if gpu == null
    then null
    else gpuDevices.${gpu};
in
  with lib; {
    options.hosting.gaming.wolf = {
      enable = mkEnableOption "Enable Games on Whales (Wolf) game streaming server";

      image = mkOption {
        type = types.str;
        default = "ghcr.io/games-on-whales/wolf:stable";
        description = "Docker image for Wolf game streaming";
      };

      configDir = mkOption {
        type = types.str;
        default = "/etc/wolf";
        description = ''
          Host directory for Wolf configuration data.
          Wolf writes its config, TLS certificates, and state here.
        '';
      };

      gpu = mkOption {
        type = types.nullOr (types.enum ["integrated" "dedicated"]);
        default = null;
        description = ''
          GPU to pass through for game rendering and encoding.

          - `null` (default): pass through `/dev/dri/` (all GPUs). Wolf auto-detects
            and defaults to the first render node (`/dev/dri/renderD128`,
            usually the integrated GPU).
          - `"integrated"`: pass only the integrated GPU (`renderD128` + `card1`).
            Best for low-power desktop streaming.
          - `"dedicated"`: pass only the dedicated GPU (`renderD129` + `card2`).
            Best for high-performance gaming.

          On most multi-GPU Linux systems, renderD128 maps to the integrated GPU
          and renderD129+ to dedicated GPUs. If your system has a different layout,
          adjust the `gpuDevices` map in the module source.

          When a specific GPU is selected, only that GPU's devices are exposed
          and the Wolf `WOLF_RENDER_NODE` env var is set to the correct render
          node. No other GPU devices are visible inside the container.
        '';
      };

      moonlightPort = mkOption {
        type = types.port;
        default = 47984;
        description = ''
          Port for the Moonlight/Sunshine RTSP server.
          Moonlight clients connect to this TCP port plus a range of UDP ports above it.
        '';
      };

      webUiPort = mkOption {
        type = types.port;
        default = 47989;
        description = ''
          HTTPS port for the Wolf web UI and PIN pairing page.
          Accessible at https://<host>:47989/.
        '';
      };

      httpPort = mkOption {
        type = types.port;
        default = 47990;
        description = ''
          HTTP port for the Wolf web UI (redirects to HTTPS by default).
        '';
      };

      streamPorts = {
        video = mkOption {
          type = types.port;
          default = 47998;
          description = "UDP port for Moonlight video stream.";
        };

        control = mkOption {
          type = types.port;
          default = 47999;
          description = "UDP port for Moonlight control stream.";
        };

        audio = mkOption {
          type = types.port;
          default = 48000;
          description = "UDP port for Moonlight audio stream.";
        };

        mic = mkOption {
          type = types.port;
          default = 48002;
          description = "UDP port for Moonlight microphone stream.";
        };

        rtsp = mkOption {
          type = types.port;
          default = 48010;
          description = ''
            TCP and UDP port for Moonlight RTSP control.
            Also used for the RTSP control TCP port alongside moonlightPort.
          '';
        };
      };

      pingPorts = {
        video = mkOption {
          type = types.port;
          default = 48100;
          description = "UDP port for Wolf RTP video ping server. Used by Moonlight to verify UDP connectivity.";
        };
        audio = mkOption {
          type = types.port;
          default = 48200;
          description = "UDP port for Wolf RTP audio ping server. Used by Moonlight to verify UDP connectivity.";
        };
      };

      logLevel = mkOption {
        type = types.enum [
          "ERROR"
          "WARNING"
          "INFO"
          "DEBUG"
          "TRACE"
        ];
        default = "INFO";
        description = "Log level for Wolf";
      };

      stopContainerOnExit = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to stop and remove app containers when the streaming client disconnects.
          Set to false to leave apps running between sessions.
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

      extraOptions = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Extra Docker options passed directly to the container runtime.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        # Auto-enable the Docker container hosting platform
        hosting.platforms.docker.enable = mkDefault true;

        # Ensure config directory exists
        systemd.tmpfiles.rules = [
          "d ${cfg.configDir} 0755 - - -"
        ];

        # Ensure /dev/uinput exists and is accessible
        # This is needed for virtual input device creation
        services.udev.extraRules = ''
          KERNEL=="uinput", MODE="0660", GROUP="input"
          KERNEL=="uhid", MODE="0660", GROUP="input"
        '';

        # Wolf container via OCI module
        virtualisation.oci-containers.containers.wolf = {
          inherit (cfg) image;
          autoStart = true;

          # Host networking is required — Wolf uses multiple ports
          # (RTSP, HTTP, HTTPS) and needs direct host network access
          # for Moonlight client discovery and streaming.
          networks = [];

          volumes = [
            "${cfg.configDir}:/etc/wolf:rw"
            "/var/run/docker.sock:/var/run/docker.sock:rw"
            "/run/udev:/run/udev:rw"
          ];

          environment =
            {
              WOLF_LOG_LEVEL = cfg.logLevel;
            }
            // optionalAttrs (!cfg.stopContainerOnExit) {
              WOLF_STOP_CONTAINER_ON_EXIT = "FALSE";
            }
            // optionalAttrs (cfg.internalMac != null) {
              WOLF_INTERNAL_MAC = cfg.internalMac;
            };

          extraOptions =
            [
              "--network=host"
              "--init"
              "--device=/dev/uinput"
              "--device=/dev/uhid"
              "--device-cgroup-rule=c 13:* rmw"
            ]
            ++ cfg.extraOptions;
        };
      }

      # ── Firewall ──────────────────────────────────
      # Wolf uses --network=host, so its ports are bound on the host.
      # The NixOS firewall blocks them by default — open the required ports
      # so Moonlight clients (including over Tailscale) can connect.
      {
        networking.firewall = {
          allowedTCPPorts = [
            cfg.moonlightPort # RTSP
            cfg.webUiPort # HTTPS web UI
            cfg.httpPort # HTTP redirect
            cfg.streamPorts.rtsp # RTSP control (TCP)
          ];

          allowedUDPPorts = [
            cfg.streamPorts.video # 47998 video stream
            cfg.streamPorts.control # 47999 control
            cfg.streamPorts.audio # 48000 audio
            cfg.streamPorts.mic # 48002 mic
            cfg.streamPorts.rtsp # 48010 RTSP (UDP)
            cfg.pingPorts.video # 48100 RTP video ping
            cfg.pingPorts.audio # 48200 RTP audio ping
          ];
        };
      }

      # ── GPU selection ──────────────────────────────
      # When null: pass entire /dev/dri/ (all GPUs), no render node override
      (mkIf (gpu == null) {
        virtualisation.oci-containers.containers.wolf = {
          volumes = [
            "/dev/:/dev/:rw"
          ];
          extraOptions = [
            "--device=/dev/dri/"
          ];
        };
      })

      # When a specific GPU is selected: pass only its devices + set render node
      (mkIf (gpu != null) {
        virtualisation.oci-containers.containers.wolf = {
          volumes = [
            "${selectedGpu.render}:${selectedGpu.render}"
            "${selectedGpu.card}:${selectedGpu.card}"
          ];
          environment.WOLF_RENDER_NODE = selectedGpu.render;
          extraOptions = [
            "--device=${selectedGpu.render}"
            "--device=${selectedGpu.card}"
          ];
        };
      })
    ]);
  }
