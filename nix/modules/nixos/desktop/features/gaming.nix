{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.features.gaming;
  inherit (config.desktop.environments) selectedEnvironment;

  consoleUser = "steam-user";
in {
  options.desktop.features.gaming = {
    enable = lib.mkEnableOption "Enable steam integration";

    vr.enable = lib.mkEnableOption "Enable WiVRn OpenXR streaming server";

    console = {
      enable = lib.mkEnableOption "Enable the Jovian Steam/GameScope session";
      autoStart = lib.mkEnableOption "Enable Jovian login takeover and boot directly into gaming mode";
      configureSystem = lib.mkEnableOption "Configure the system for steamdeck-like behaviour";
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = {};
        description = ''
          Environment variables to apply to the Jovian gamescope session.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.console.enable || !cfg.console.autoStart || selectedEnvironment != null;
        message = ''
          desktop.features.gaming.console.autoStart requires a supported desktop environment to provide a Jovian desktop fallback session automatically.
          Detected environment: ${selectedEnvironment}
        '';
      }
    ];

    environment.systemPackages = with pkgs;
      [
        moonlight-qt # Cloud streaming

        mangohud # Overlay for monitoring
      ]
      ++ lib.optional cfg.vr.enable sidequest;

    services.wivrn = lib.mkIf cfg.vr.enable {
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

    # The Jovian module requires a dedicated system user for the gamescope session.
    # Define it directly rather than via core.users (which would force isNormalUser).
    users.groups.${consoleUser} = {};
    users.users.${consoleUser} = {
      description = "Dedicated Jovian console session account";
      hashedPassword = "!";
      isSystemUser = true;
      group = consoleUser;
    };

    # Ensure Stylix doesn't fail on the steam-user (it's not a full desktop user).
    # Inherit the system theme, falling back to a dark default.
    home-manager.users.${consoleUser}.stylix.base16Scheme =
      lib.mkDefault (config.themes.base16Scheme or "${pkgs.base16-schemes}/share/themes/catppuccin-macchiato.yaml");

    jovian = lib.mkIf cfg.console.enable {
      steam =
        {
          inherit (cfg.console) autoStart environment;

          enable = true;
          user = consoleUser;
        }
        // lib.optionalAttrs cfg.console.autoStart {
          desktopSession = selectedEnvironment;
        };
      steamos.useSteamOSConfig = cfg.console.configureSystem;
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
