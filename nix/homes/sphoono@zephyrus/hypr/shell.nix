{
  pkgs,
  config,
  nixosConfig,
  ...
}: {
  config = {
    sops = {
      secrets."api/OPENROUTER_API_KEY" = {};
      templates."noctalia.env".content = ''
        NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY=${config.sops.placeholder."api/OPENROUTER_API_KEY"}
      '';
    };

    xdg.portal.extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
    ];

    home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
      defaultWallpaper = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers/default.png";
    };

    programs.noctalia-shell = {
      enable = true;
      package = pkgs.noctalia-shell.override {
        calendarSupport = true;
        gpuScreenRecorderSupport = true;
      };
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
          network-manager-vpn = standardPlugin;
        };
      };
      pluginSettings = {
        usb-drive-manager = {
          autoMount = true;
          hideWhenEmpty = true;
        };
        tailscale = {
          showPeerCount = false;
          terminalCommand = "${
            if (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM)
            then "uwsm app -s a "
            else ""
          }${config.programs.ghostty.package}/bin/ghostty -e";
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
          customLaunchPrefix =
            if (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM)
            then "uwsm app -s a"
            else "";
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
        systemMonitor.externalMonitor = "${
          if (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM)
          then "uwsm app -s a "
          else ""
        }${config.programs.ghostty.package}/bin/ghostty -e ${config.programs.btop.package}/bin/btop";
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
        "match:namespace noctalia-background-.*$, ignore_alpha 0.5, blur on, blur_popups on"
      ];

      bind = [
        "SUPER, A, exec, noctalia-shell ipc call launcher toggle"
        "SUPER, Tab, exec, noctalia-shell ipc call controlCenter toggle"
        "SUPER, comma, exec, noctalia-shell ipc call settings toggle"
        "SUPER, L, exec, noctalia-shell ipc call sessionMenu toggle"
      ];
    };

    systemd.user.services.noctalia-shell = {
      Unit = {
        Description = "Noctalia Shell";
        PartOf = ["graphical-session.target"];
        After = ["graphical-session.target"];
      };
      Service = {
        ExecStart = "${config.programs.noctalia-shell.package}/bin/noctalia-shell";
        EnvironmentFile = config.sops.templates."noctalia.env".path;
        Restart = "on-failure";
      };
      Install = {
        WantedBy = ["graphical-session.target"];
      };
    };
  };
}
