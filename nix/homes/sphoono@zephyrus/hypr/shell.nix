{
  pkgs,
  config,
  ...
}: {
  config = {
    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];

    home.sessionVariables = {
      NOCTALIA_AP_GOOGLE_API_KEY = "$GOOGLE_AI_API_KEY";
    };

    programs.noctalia-shell = {
      enable = true;
      plugins = {
        sources = [
          {
            enabled = true;
            name = "Official Noctalia Plugins";
            url = "https://github.com/noctalia-dev/noctalia-plugins";
          }
        ];
        states = let
          standardPlugin = {
            enabled = true;
            sourceUrl = "https://github.com/noctalia-dev/noctalia-plugins";
          };
        in {
          polkit-agent = standardPlugin;
          assistant-panel = standardPlugin;
          special-workspaces = standardPlugin;
          screen-recorder = standardPlugin;
          usb-drive-manager = standardPlugin;
          tailscale = standardPlugin;
        };
      };
      pluginSettings = {
        usb-drive-manager = {
          autoMount = true;
          hideWhenEmpty = true;
        };
        tailscale = {
          showPeerCount = false;
          terminalCommand = "${config.programs.ghostty.package}/bin/ghostty -e";
          taildropReceiveMode = "pkexec";
        };
      };
      settings = let
        monitors = [
          "eDP-1"
        ];
      in {
        appLauncher = {
          enableClipboardHistory = true;
          position = "follow_bar";
          terminalCommand = "${config.programs.ghostty.package}/bin/ghostty -e";
          customLaunchPrefixEnabled = true;
          customLaunchPrefix = "uwsm app";
          density = "compact";
        };
        audio = {
          spectrumFrameRate = 60;
          visualizerType = "mirrored";
        };
        colorSchemes.schedulingMode = "on";
        general = {
          avatarImage = "${config.home.homeDirectory}/.face";
          enableLockScreenMediaControls = true;
          showScreenCorners = true;
          forceBlackScreenCorners = true;
          lockScreenAnimations = true;
          lockScreenBlur = 0.5;
          lockScreenTint = 0.5;
          passwordChars = true;
        };
        idle.enabled = true;
        location = {
          name = "Denton, TX";
          useFahrenheit = true;
          use12HourFormat = true;
        };
        network = {
          bluetoothHideUnnamedDevices = true;
          bluetoothRssiPollingEnabled = true;
          disableDiscoverability = true;
        };
        nightlight.enabled = true;
        noctaliaPerformance.disableWallpaper = true;
        sessionMenu.position = "center";
        systemMonitor.externalMonitor = "${config.programs.ghostty.package}/bin/ghostty -e btop";
        wallpaper.directory = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";
        bar = {
          barType = "floating";
          monitors = ["eDP-1"];
          widgets = {
            left = [
              {
                id = "plugin:assistant-panel";
              }
              {
                id = "Workspace";
              }
              {
                id = "plugin:special-workspaces";
              }
              {
                id = "SystemMonitor";
              }
              {
                id = "plugin:screen-recorder";
              }
            ];
            center = [
              {
                id = "MediaMini";
              }
            ];
            right = [
              {
                id = "Tray";
              }
              {
                id = "plugin:tailscale";
              }
              {
                id = "Brightness";
              }
              {
                id = "Battery";
              }
              {
                id = "Volume";
              }
              {
                id = "plugin:usb-drive-manager";
              }
              {
                id = "Clock";
              }
              {
                id = "NotificationHistory";
              }
              {
                id = "ControlCenter";
              }
            ];
          };
        };
        dock.enabled = false;
        notifications = {
          inherit monitors;
        };
        osd = {
          inherit monitors;
        };
        ui = {
          boxBorderEnabled = true;
          settingsPanelSideBarCardStyle = true;
          translucentWidgets = true;
        };
      };
    };

    wayland.windowManager.hyprland.settings = {
      layerrule = [
        "match:namespace noctalia-shell:regionSelector, no_anim on"
      ];

      exec-once = [
        "noctalia-shell"
      ];

      bind = [
        "SUPER, A, exec, noctalia-shell ipc call launcher toggle"
        "SUPER, Tab, exec, noctalia-shell ipc call controlCenter toggle"
        "SUPER, comma, exec, noctalia-shell ipc call settings toggle"
        "SUPER, L, exec, noctalia-shell ipc call sessionMenu toggle"
      ];
    };
  };
}
