{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.personal.noctalia;
in
  with lib; {
    options.personal.noctalia = {
      enable = mkEnableOption "Enable Noctalia shell configuration";

      monitors = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Monitor names used by Noctalia shell surfaces.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        nix.settings = {
          extra-substituters = ["https://noctalia.cachix.org"];
          extra-trusted-public-keys = [
            "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
          ];
        };

        home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
          defaultWallpaper = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers/default.png";
        };

        programs.noctalia-shell = {
          enable = true;
          package = pkgs.noctalia-shell.override {
            calendarSupport = true;
            gpuScreenRecorderSupport = true;
          };
          plugins = let
            url = "https://github.com/noctalia-dev/noctalia-plugins";
          in {
            sources = [
              {
                inherit url;
                enabled = true;
                name = "Official Noctalia Plugins";
              }
            ];
            states = let
              standardPlugin = {
                enabled = true;
                sourceUrl = url;
              };
            in {
              polkit-agent = standardPlugin;
              special-workspaces = standardPlugin;
              pomodoro = standardPlugin;
              screen-recorder = standardPlugin;
              network-manager-vpn = standardPlugin;
              usb-drive-manager = standardPlugin;
              tailscale = standardPlugin;
            };
          };
          pluginSettings = {
            usb-drive-manager = {
              autoMount = true;
              hideWhenEmpty = true;
              fileBrowser = "xdg-open";
              terminalCommand = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e";
            };
            tailscale = {
              showPeerCount = false;
              terminalCommand = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e";
              taildropReceiveMode = "pkexec";
            };
            # 25m work + 15m break, repeated 6 times = 4h; long break same length as short here
            pomodoro = {
              workDuration = 25;
              shortBreakDuration = 15;
              longBreakDuration = 15;
              sessionsBeforeLongBreak = 6;
              autoStartBreaks = true;
              autoStartWork = true;
            };
          };
          settings = {
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
            colorSchemes.schedulingMode = "dark";
            general = {
              avatarImage = "${config.home.homeDirectory}/Nextcloud/Pictures/.face";
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
              name = "Fort Worth, TX";
              useFahrenheit = true;
              use12HourFormat = true;
            };
            network = {
              bluetoothHideUnnamedDevices = true;
              bluetoothRssiPollingEnabled = true;
              disableDiscoverability = true;
            };
            nightLight.enabled = true;
            noctaliaPerformance.disableWallpaper = true;
            sessionMenu.position = "center";
            systemMonitor.externalMonitor = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e ${config.programs.btop.package}/bin/btop";
            wallpaper.directory = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";
            bar = {
              inherit (cfg) monitors;

              barType = "floating";
              widgets = {
                left = [
                  {
                    id = "plugin:pomodoro";
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
            dock.enabled = false;
            notifications.monitors = cfg.monitors;
            osd.monitors = cfg.monitors;
            ui = {
              boxBorderEnabled = true;
              settingsPanelSideBarCardStyle = true;
              translucentWidgets = true;
            };
          };
        };
      }

      (mkIf config.wayland.windowManager.hyprland.enable {
        # TODO: Migrate this back to hyprland module
        wayland.windowManager.hyprland.settings = {
          on = {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''
                function()
                  hl.exec_cmd("${pkgs.uwsm}/bin/uwsm app -s b -t service noctalia-shell")
                end
              '')
            ];
          };

          layer_rule = [
            {
              match = {
                namespace = "noctalia-shell:regionSelector";
              };
              no_anim = true;
            }
            {
              match = {
                namespace = "noctalia-background-.*$";
              };
              ignore_alpha = 0.5;
              blur = true;
              blur_popups = true;
            }
          ];

          bind = [
            {
              _args = [
                "SUPER + A"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call launcher toggle\")")
              ];
            }
            {
              _args = [
                "SUPER + Tab"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call controlCenter toggle\")")
              ];
            }
            {
              _args = [
                "SUPER + L"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call lockScreen lock\")")
              ];
            }
            {
              _args = [
                "SUPER + P"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call sessionMenu toggle\")")
              ];
            }
            {
              _args = [
                "SUPER + C"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call launcher emoji\")")
              ];
            }
            {
              _args = [
                "SUPER + V"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call launcher clipboard\")")
              ];
            }

            # Mic Mute
            {
              _args = [
                "XF86AudioMicMute"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call volume muteInput\")")
              ];
            }

            # Display
            {
              _args = [
                "XF86MonBrightnessDown"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call brightness decrease\")")
                {
                  locked = true;
                  repeating = true;
                }
              ];
            }
            {
              _args = [
                "XF86MonBrightnessUp"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call brightness increase\")")
                {
                  locked = true;
                  repeating = true;
                }
              ];
            }

            # Audio
            {
              _args = [
                "XF86AudioMute"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call volume muteOutput\")")
                {locked = true;}
              ];
            }
            {
              _args = [
                "XF86AudioLowerVolume"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call volume decrease\")")
                {
                  locked = true;
                  repeating = true;
                }
              ];
            }
            {
              _args = [
                "XF86AudioRaiseVolume"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call volume increase\")")
                {
                  locked = true;
                  repeating = true;
                }
              ];
            }

            # Media
            {
              _args = [
                "XF86AudioPrev"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call media previous\")")
                {locked = true;}
              ];
            }
            {
              _args = [
                "XF86AudioPlay"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call media playPause\")")
                {locked = true;}
              ];
            }
            {
              _args = [
                "XF86AudioNext"
                (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call media next\")")
                {locked = true;}
              ];
            }
          ];
        };
      })
    ]);
  }
