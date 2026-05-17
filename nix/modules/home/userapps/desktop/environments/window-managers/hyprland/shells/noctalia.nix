{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.environments.window-managers.hyprland.shells.noctalia;
  hyprCfg = config.userapps.desktop.environments.window-managers.hyprland;
  terminal = config.home.sessionVariables.TERMINAL or "ghostty";
in
  with lib; {
    options.userapps.desktop.environments.window-managers.hyprland.shells.noctalia = {
      enable = mkEnableOption "Noctalia shell for Hyprland (bar, OSD, lockscreen, notifications)";

      monitors = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Monitor names for Noctalia shell surfaces (bar, notifications, OSD).";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.noctalia-shell.override {
          calendarSupport = true;
          gpuScreenRecorderSupport = true;
        };
        description = "Noctalia shell package to use.";
      };

      pluginSources = mkOption {
        type = with types;
          listOf (submodule {
            options = {
              url = mkOption {
                type = str;
                description = "Git URL for the plugin source.";
              };
              name = mkOption {
                type = str;
                default = "Official Noctalia Plugins";
                description = "Display name for the plugin source.";
              };
              enabled = mkOption {
                type = bool;
                default = true;
                description = "Whether to enable this plugin source.";
              };
            };
          });
        default = [
          {
            url = "https://github.com/noctalia-dev/noctalia-plugins";
            name = "Official Noctalia Plugins";
            enabled = true;
          }
        ];
        description = "Plugin sources for Noctalia shell.";
      };

      pluginStates = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              enable = mkOption {
                type = bool;
                default = true;
                description = "Whether to enable this plugin.";
              };
              sourceUrl = mkOption {
                type = str;
                description = "Git URL of the plugin source.";
              };
            };
          });
        default = {};
        description = "Plugin states for Noctalia shell plugins.";
      };

      settings = mkOption {
        type = with types; attrs;
        default = {};
        description = "Additional Noctalia shell settings.";
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = hyprCfg.enable;
          message = "Noctalia shell requires the Hyprland desktop module to be enabled.";
        }
      ];

      # Noctalia package source
      nix.settings = {
        extra-substituters = ["https://noctalia.cachix.org"];
        extra-trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };

      programs.noctalia-shell = {
        enable = true;
        inherit (cfg) package;

        sources =
          map (source: {
            inherit (source) url;
            inherit (source) enabled;
            inherit (source) name;
          })
          cfg.pluginSources;

        plugins =
          mapAttrsToList (name: state: {
            inherit name;
            enabled = state.enable;
            inherit (state) sourceUrl;
          })
          cfg.pluginStates;

        settings =
          {
            appLauncher = {
              enableClipboardHistory = true;
              position = "follow_bar";
              terminalCommand = "${terminal} -e";
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
              enableLockScreenMediaControls = true;
              showScreenCorners = true;
              forceBlackScreenCorners = true;
              lockScreenAnimations = true;
              lockScreenBlur = 0.5;
              lockScreenTint = 0.5;
              passwordChars = true;
            };
            idle.enabled = true;
            network = {
              bluetoothHideUnnamedDevices = true;
              bluetoothRssiPollingEnabled = true;
              disableDiscoverability = true;
            };
            nightLight.enabled = true;
            sessionMenu.position = "center";
            systemMonitor.externalMonitor = "${pkgs.run-application}/bin/run-application ${terminal} -e ${config.programs.btop.package}/bin/btop";
            noctaliaPerformance.disableWallpaper = true;
            bar = {
              inherit (cfg) monitors;
              barType = "floating";
              widgets = {
                left = [
                  {id = "plugin:pomodoro";}
                  {id = "Workspace";}
                  {id = "plugin:special-workspaces";}
                  {id = "SystemMonitor";}
                  {id = "plugin:screen-recorder";}
                ];
                center = [{id = "MediaMini";}];
                right = [
                  {id = "Tray";}
                  {id = "plugin:network-manager-vpn";}
                  {id = "plugin:tailscale";}
                  {id = "Brightness";}
                  {id = "Battery";}
                  {id = "Volume";}
                  {id = "plugin:usb-drive-manager";}
                  {id = "Clock";}
                  {id = "NotificationHistory";}
                  {id = "ControlCenter";}
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
          }
          // cfg.settings;
      };

      # Wire up Hyprland integration for Noctalia
      wayland.windowManager.hyprland.settings = mkIf hyprCfg.enable {
        layer_rule = [
          {
            match.namespace = "noctalia-shell:regionSelector";
            no_anim = true;
          }
          {
            match.namespace = "noctalia-background-.*$";
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
          {
            _args = [
              "XF86AudioMicMute"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call volume muteInput\")")
            ];
          }
          # ── Hardware Keys ──────────────────────────────────────────
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
    };
  }
