{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.desktop.window-managers.shells.noctalia;
  hyprCfg = config.desktop.window-managers.hyprland;
  terminal = config.home.sessionVariables.TERMINAL;
in
  with lib; {
    options.desktop.window-managers.shells.noctalia = {
      enable = mkEnableOption "Noctalia shell for Hyprland (bar, OSD, lockscreen, notifications)";

      monitors = mkOption {
        type = with types; listOf str;
        default = [];
        description = "Monitor names for Noctalia shell surfaces (bar, notifications, OSD).";
      };

      package = mkOption {
        type = types.package;
        default = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultText = literalExpression "inputs.noctalia.packages.\${pkgs.stdenv.hostPlatform.system}.default";
        description = "Noctalia package to use.";
      };

      systemd = {
        enable =
          mkEnableOption "Noctalia systemd user service"
          // {
            default = true;
          };
      };

      wallpaperDir = mkOption {
        type = types.str;
        default = "${config.home.homeDirectory}/Pictures/Wallpapers";
        description = "Directory containing wallpapers for Noctalia.";
      };

      avatarImage = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Path to the avatar image for the lock screen and user menu.";
      };

      location = mkOption {
        type = with types;
          nullOr (submodule {
            options = {
              name = mkOption {
                type = str;
                description = "Display name for the location.";
              };
              useFahrenheit = mkOption {
                type = bool;
                default = false;
                description = "Whether to use Fahrenheit for temperature.";
              };
              use12HourFormat = mkOption {
                type = bool;
                default = false;
                description = "Whether to use 12-hour time format.";
              };
            };
          });
        default = null;
        description = "Location configuration for weather and time display.";
      };

      settings = mkOption {
        type = types.attrs;
        default = {};
        description = "Additional Noctalia shell settings (merged into base config, converted to TOML).";
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

      programs.noctalia = {
        enable = true;
        inherit (cfg) package;
        systemd.enable = cfg.systemd.enable;

        settings =
          {
            appLauncher = {
              enableClipboardHistory = true;
              terminalCommand = "${terminal} -e";
              customLaunchPrefixEnabled = true;
              customLaunchPrefix = "${pkgs.runapp}/bin/runapp";
              viewMode = "grid";
            };
            audio = {
              spectrumFrameRate = 60;
              visualizerType = "mirrored";
            };
            colorSchemes.schedulingMode = "dark";
            general =
              {
                enableLockScreenMediaControls = true;
                showScreenCorners = true;
                forceBlackScreenCorners = true;
                lockScreenAnimations = true;
                lockScreenBlur = 0.5;
                lockScreenTint = 0.5;
                passwordChars = true;
              }
              // optionalAttrs (cfg.avatarImage != null) {
                inherit (cfg) avatarImage;
              };
            idle.enabled = true;
            location = optionalAttrs (cfg.location != null) {
              inherit (cfg.location) name useFahrenheit use12HourFormat;
            };
            network = {
              bluetoothHideUnnamedDevices = true;
              disableDiscoverability = true;
            };
            nightLight.enabled = true;
            systemMonitor.externalMonitor = "${pkgs.runapp}/bin/runapp -- ${terminal} -e ${config.programs.btop.package}/bin/btop";
            wallpaper = {
              overviewEnabled = true;
              directory = cfg.wallpaperDir;
            };
            bar = {
              inherit (cfg) monitors;
              barType = "simple";
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
              panelBackgroundOpacity = 0.9;
              boxBorderEnabled = true;
              settingsPanelSideBarCardStyle = true;
              translucentWidgets = true;
            };
          }
          // cfg.settings;
      };

      desktop.window-managers.hyprland.autostart = [
        "noctalia"
      ];

      # Wire up Hyprland integration for Noctalia
      wayland.windowManager.hyprland.settings = mkIf hyprCfg.enable {
        layer_rule = [
          {
            match.namespace = "noctalia:regionSelector";
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
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call launcher toggle\")")
            ];
          }
          {
            _args = [
              "SUPER + Tab"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call controlCenter toggle\")")
            ];
          }
          {
            _args = [
              "SUPER + L"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call lockScreen lock\")")
            ];
          }
          {
            _args = [
              "SUPER + P"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call sessionMenu toggle\")")
            ];
          }
          {
            _args = [
              "SUPER + C"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call launcher emoji\")")
            ];
          }
          {
            _args = [
              "SUPER + V"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call launcher clipboard\")")
            ];
          }
          {
            _args = [
              "XF86AudioMicMute"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call volume muteInput\")")
            ];
          }
          # ── Hardware Keys ──────────────────────────────────────────
          {
            _args = [
              "XF86MonBrightnessDown"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call brightness decrease\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessUp"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call brightness increase\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioMute"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call volume muteOutput\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioLowerVolume"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call volume decrease\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioRaiseVolume"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call volume increase\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioPrev"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call media previous\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioPlay"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call media playPause\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioNext"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia ipc call media next\")")
              {locked = true;}
            ];
          }
        ];
      };
    };
  }
