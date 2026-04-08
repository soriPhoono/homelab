{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.personal.hyprland;
in
  with lib; {
    config = mkIf cfg.enable {
      nix.settings = {
        extra-substituters = ["https://noctalia.cachix.org"];
        extra-trusted-public-keys = ["noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="];
      };

      sops = {
        secrets."api/OPENROUTER_API_KEY" = {};
        templates."noctalia.env".content = ''
          NOCTALIA_AP_OPENAI_COMPATIBLE_API_KEY=${config.sops.placeholder."api/OPENROUTER_API_KEY"}
        '';
      };

      xdg.portal.extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
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
            network-manager-vpn = standardPlugin;
            usb-drive-manager = standardPlugin;
            tailscale = standardPlugin;
          };
        };
        pluginSettings = {
          assistant-panel = {
            ai = {
              provider = "openai_compatible";
              openaiBaseUrl = "https://openrouter.ai/api/v1/chat/completions";
              model = "gemini-3.1-flash-lite-preview";
            };
          };
          usb-drive-manager = {
            autoMount = true;
            hideWhenEmpty = true;
          };
          tailscale = {
            showPeerCount = false;
            terminalCommand = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e";
            taildropReceiveMode = "pkexec";
          };
        };
        settings = let
          monitors = map (monitor: monitor.name) cfg.monitors;
        in {
          appLauncher = {
            enableClipboardHistory = true;
            position = "follow_bar";
            terminalCommand = "${config.home.sessionVariables.TERMINAL} -e";
            customLaunchPrefixEnabled = true;
            customLaunchPrefix = "${pkgs.run-application}/bin/run-application";
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
          idle.enabled =
            true;
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
          nightLight.enabled =
            true;
          noctaliaPerformance.disableWallpaper =
            true;
          sessionMenu.position = "center";
          systemMonitor.externalMonitor = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e ${config.programs.btop.package}/bin/btop";
          wallpaper.directory = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";
          bar = {
            inherit monitors;

            barType = "floating";
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
                  id = "plugin:network-manager-vpn";
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
          dock.enabled =
            false;
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
          "SUPER, L, exec, noctalia-shell ipc call lockScreen lock"
          "SUPER, P, exec, noctalia-shell ipc call sessionMenu toggle"
          "SUPER, V, exec, noctalia-shell ipc call launcher clipboard"
          "SUPER, C, exec, noctalia-shell ipc call launcher emoji"

          # Mic Mute
          ", XF86AudioMicMute, exec, noctalia-shell ipc call volume muteInput"
        ];

        bindl = [
          # Audio
          ", XF86AudioMute, exec, noctalia-shell ipc call volume muteOutput"

          # Media
          ", XF86AudioPrev, exec, noctalia-shell ipc call media previous"
          ", XF86AudioPlay, exec, noctalia-shell ipc call media playPause"
          ", XF86AudioNext, exec, noctalia-shell ipc call media next"
        ];

        bindle = [
          # Volume
          ", XF86AudioLowerVolume, exec, noctalia-shell ipc call volume decrease"
          ", XF86AudioRaiseVolume, exec, noctalia-shell ipc call volume increase"

          # Brightness
          ", XF86MonBrightnessDown, exec, noctalia-shell ipc call brightness decrease"
          ", XF86MonBrightnessUp, exec, noctalia-shell ipc call brightness increase"
        ];
      };

      systemd.user.services.noctalia-shell = {
        Unit = {
          Description = "Noctalia Shell";
          PartOf = ["wayland-session@hyprland.desktop.target"];
          After = ["wayland-session@hyprland.desktop.target" "wayland-wm@hyprland.desktop.service"];
          Before = ["wayland-session-shutdown.target"];
        };
        Service = {
          ExecStart = "${config.programs.noctalia-shell.package}/bin/noctalia-shell";
          EnvironmentFile = config.sops.templates."noctalia.env".path;
          Restart = "on-failure";
        };
        Install = {
          WantedBy = ["wayland-session@hyprland.desktop.target"];
        };
      };
    };
  }
