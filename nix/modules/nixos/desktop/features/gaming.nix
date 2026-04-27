{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.features.gaming;
in {
  options.desktop.features.gaming = {
    enable = lib.mkEnableOption "Enable steam integration";
    wivrn.enable = lib.mkEnableOption "Enable WiVRn OpenXR streaming server";

    gamescope = {
      enable = lib.mkEnableOption "Enable Steam Gamescope session";
      width = lib.mkOption {
        type = lib.types.int;
        default = 1920;
        description = "Width of the gamescope session";
      };
      height = lib.mkOption {
        type = lib.types.int;
        default = 1080;
        description = "Height of the gamescope session";
      };
      refreshRate = lib.mkOption {
        type = lib.types.int;
        default = 60;
        description = "Refresh rate of the gamescope session";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs;
      [
        mangohud # Overlay for monitoring
        moonlight-qt # Cloud streaming
      ]
      ++ lib.optional cfg.wivrn.enable sidequest;

    services.wivrn = lib.mkIf cfg.wivrn.enable {
      enable = true;
      openFirewall = true;
      autoStart = true;
      highPriority = true;
      steam.importOXRRuntimes = true;
    };

    programs = {
      gamemode.enable = true;

      steam = {
        enable = true;

        extest.enable = true;
        protontricks.enable = true;

        extraCompatPackages = with pkgs; [
          proton-ge-bin
        ];
      };
    };

    networking.networkmanager.dispatcherScripts = [
      {
        source = "${pkgs.writeShellApplication {
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
        }}/bin/fix_roaming";
      }
    ];
  };
}
