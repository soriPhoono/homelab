{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.features.gaming;
  inherit (config.desktop.environments) selectedEnvironment;
in
  with lib; {
    options.desktop.features.gaming = {
      desktop = {
        enable = mkEnableOption "Enable desktop gaming clients on this system";

        clients = mkOption {
          type = types.listOf (types.enum [
            "steam"
            "lutris"
            "prismlauncher"
            "gzdoom"
          ]);
          default = [
            "steam"
            "lutris"
          ];
          description = ''
            List of game clients to install on the system. Select from a list of known gaming applications.
          '';
        };
      };

      console = {
        enable = mkEnableOption "Enable the Jovian Steam/GameScope session";

        autoStart = mkEnableOption "Enable Jovian login takeover and boot directly into gaming mode";
        configureSystem = mkEnableOption "Configure the system for steamdeck-like behaviour";

        environment = mkOption {
          type = types.attrsOf types.str;
          default = {};
          description = ''
            Environment variables to apply to the Jovian gamescope session.
          '';
        };
      };

      vr.enable = mkEnableOption "Enable WiVRn OpenXR streaming server for Meta Quest devices";

      streaming = {
        enable = mkEnableOption "Enable wolf games-on-whales streaming server integration on this system (Will pull in podman)";

        mode = mkOption {
          type = types.enum ["client" "server"];
          default = "client";
          description = ''
            Toggle the modules behaviour between creating a client with the moonlight streaming application installed,
            or a server with podman running the gaming-on-whales wolf game streaming server. Enabling the server will
            open firewall ports on the system for discovery.
          '';
        };
      };
    };

    config = mkMerge [
      (mkIf cfg.desktop.enable {
        environment.systemPackages = with pkgs; [
          # Core gaming packages (perf monitors, basic game launchers, etc)
          mangohud

          (mkIf (elem "lutris" cfg.desktop.clients) lutris)
          (mkIf (elem "prismlauncher" cfg.desktop.clients) prismlauncher)
          (mkIf (elem "gzdoom" cfg.desktop.clients) gzdoom)
        ];

        programs = {
          gamemode.enable = true;

          steam = mkIf (elem "steam" cfg.desktop.clients) {
            enable = true;

            extest.enable = true;
            protontricks.enable = true;

            extraCompatPackages = with pkgs; [
              proton-ge-bin
            ];
          };
        };
      })
      (mkIf cfg.console.enable {
        assertions = [
          {
            assertion = !(cfg.console.autoStart && selectedEnvironment == null);
            message = ''
              desktop.features.gaming.console.autoStart requires a supported desktop environment to provide a Jovian desktop fallback session automatically.
              Detected environment: null
            '';
          }
        ];

        jovian = {
          steam =
            {
              inherit (cfg.console) autoStart environment;

              enable = true;
            }
            // optionalAttrs cfg.console.autoStart {
              desktopSession = selectedEnvironment;
            };
          steamos.useSteamOSConfig = cfg.console.configureSystem;
        };
      })
      (mkIf cfg.vr.enable {
        # Sidequest for sideloading and managing games and apps on a Meta Quest VR headset
        environment.systemPackages = with pkgs; [
          sidequest
        ];

        # WiVRn for OpenXR streaming server (linux-native alternative to Virtual Desktop for Quest devices)
        services.wivrn = mkIf (cfg.desktop.enable || cfg.console.enable) {
          enable = true;
          openFirewall = true;
          autoStart = true;
          highPriority = true;
          steam.importOXRRuntimes = true;
        };
      })
      (mkIf cfg.streaming.enable {
        hosting.platforms.podman.enable = true;

        environment.systemPackages = with pkgs; [
          (mkIf (cfg.streaming.mode == "client") moonlight-qt)
        ];

        networking.networkmanager.dispatcherScripts = mkIf (cfg.streaming.mode == "client") [
          {
            source = "${
              pkgs.writeShellApplication {
                name = "fix_roaming";
                runtimeInputs = with pkgs; [
                  iw
                  gnugrep
                  systemd
                ];
                text = ''
                  set -e

                  # Run only when an interface is up
                  if [[ "$2" != "up" ]]; then
                      exit 0
                  fi

                  # Check that the interface that went up is a wireless one
                  if iw dev | grep -wq "$1"; then
                      ALL_NETS="$(busctl tree fi.w1.wpa_supplicant1 | grep -Eo '/fi/w1/wpa_supplicant1/Interfaces/.+/Networks/[[:digit:]]+')"

                      for DBUS_PATH_TO_NET in $ALL_NETS; do
                          busctl  call --system \
                                  fi.w1.wpa_supplicant1 \
                                  "$DBUS_PATH_TO_NET" \
                                  org.freedesktop.DBus.Properties Set \
                                  ssv \
                                  fi.w1.wpa_supplicant1.Network Properties \
                                  'a{sv}' 1 \
                                  bgscan s "simple:30:-80:86400"
                      done
                  fi
                '';
              }
            }/bin/fix_roaming";
          }
        ];
      })
    ];
  }
