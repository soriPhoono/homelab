# Add support for external monitor brightness adjustment
{
  lib,
  pkgs,
  config,
  inputs,
  ...
}: let
  cfg = config.desktop.window-managers.shells.noctalia;
  hyprCfg = config.desktop.window-managers.hyprland;
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

        customPalettes = optionalAttrs (config.stylix.enable or false) {
          stylix = let
            inherit
              (config.lib.stylix.colors.withHashtag)
              base00
              base01
              base02
              base03
              base04
              base05
              base07
              base08
              base0A
              base0B
              base0C
              base0D
              base0E
              ;
          in {
            dark = {
              mPrimary = base0D;
              mOnPrimary = base00;
              mSecondary = base0E;
              mOnSecondary = base00;
              mTertiary = base0C;
              mOnTertiary = base00;
              mError = base08;
              mOnError = base00;
              mSurface = base00;
              mOnSurface = base05;
              mSurfaceVariant = base01;
              mOnSurfaceVariant = base04;
              mOutline = base03;
              mShadow = base00;
              mHover = base02;
              mOnHover = base05;
              terminal = {
                background = base00;
                foreground = base05;
                cursor = base05;
                cursorText = base00;
                selectionBg = base05;
                selectionFg = base00;
                normal = {
                  black = base00;
                  red = base08;
                  green = base0B;
                  yellow = base0A;
                  blue = base0D;
                  magenta = base0E;
                  cyan = base0C;
                  white = base05;
                };
                bright = {
                  black = base03;
                  red = base08;
                  green = base0B;
                  yellow = base0A;
                  blue = base0D;
                  magenta = base0E;
                  cyan = base0C;
                  white = base07;
                };
              };
            };
          };
        };

        settings =
          {
            # ── Shell ────────────────────────────────────────────────
            shell =
              {
                time_format =
                  if cfg.location != null && cfg.location.use12HourFormat
                  then "{:%I:%M %p}"
                  else "{:%H:%M}";
                date_format = "%A, %x";
                show_location = true;
                clipboard_enabled = true;
                password_style = "default";
                settings_show_advanced = false;

                panel = {
                  transparency_mode = "solid";
                  borders = true;
                  launcher_placement = "centered";
                  clipboard_placement = "centered";
                  control_center_placement = "attached";
                  session_placement = "attached";
                };
              }
              // optionalAttrs (cfg.avatarImage != null) {
                avatar_path = cfg.avatarImage;
              };

            # ── Wallpaper ───────────────────────────────────────────
            wallpaper = {
              enabled = true;
              directory = cfg.wallpaperDir;
            };

            # ── Bar ──────────────────────────────────────────────────
            bar.main = {
              position = "top";
              background_opacity = 0.9;
              radius = 12;
              margin_h = 180;
              margin_v = 10;
              padding = 14;
              widget_spacing = 6;
              scale = 1.0;
              shadow = true;
              auto_hide = false;
              reserve_space = true;
              capsule = false;
              start = [
                "launcher"
                "workspaces"
                "cpu"
                "temp"
                "ram"
              ];
              center = [
                "media"
              ];
              end = [
                "tray"
                "network"
                "bluetooth"
                "battery"
                "volume"
                "notifications"
                "clock"
                "session"
              ];
            };

            # ── Dock ─────────────────────────────────────────────────
            dock.enabled = false;

            # ── Notifications ────────────────────────────────────────
            notification = {
              enable_daemon = true;
              show_app_name = true;
              show_actions = true;
              layer = "top";
              scale = 1.0;
              background_opacity = 0.97;
              offset_x = 20;
              offset_y = 8;
            };

            # ── OSD ─────────────────────────────────────────────────
            osd = {
              position = "top_right";
              orientation = "horizontal";
              scale = 1.0;
              background_opacity = 0.97;
              offset_x = 20;
              offset_y = 8;
              kinds = {
                volume = true;
                volume_output = true;
                volume_input = true;
                brightness = true;
                wifi = true;
                bluetooth = true;
                power_profile = true;
                caffeine = true;
                dnd = true;
                lock_keys = true;
                keyboard_layout = true;
              };
            };

            # ── Lock Screen ─────────────────────────────────────────
            lockscreen = {
              blurred_desktop = false;
              blur_intensity = 0.5;
              tint_intensity = 0.3;
            };

            # ── System Monitor ───────────────────────────────────────
            system.monitor = {
              enabled = true;
              cpu_poll_seconds = 2.0;
              gpu_poll_seconds = 5.0;
              memory_poll_seconds = 2.0;
              network_poll_seconds = 3.0;
              disk_poll_seconds = 10.0;
            };

            # ── Audio ───────────────────────────────────────────────
            audio = {
              enable_overdrive = false;
              enable_sounds = false;
              sound_volume = 0.5;
            };

            # ── Night Light ─────────────────────────────────────────
            nightlight = {
              enabled = true;
              force = false;
              temperature_day = 6500;
              temperature_night = 4000;
            };

            # ── Theme ───────────────────────────────────────────────
            theme = {
              mode = "dark";
              source = "builtin";
              builtin = "Catppuccin";
              templates.enable_builtin_templates = true;
            };

            # ── Location ────────────────────────────────────────────
            location = optionalAttrs (cfg.location != null) {
              address = cfg.location.name;
            };

            # ── Weather ─────────────────────────────────────────────
            weather = {
              enabled = cfg.location != null;
              unit =
                if cfg.location != null && cfg.location.useFahrenheit
                then "fahrenheit"
                else "celsius";
              refresh_minutes = 30;
              effects = true;
            };

            # ── Idle ────────────────────────────────────────────────
            idle = {
              behavior.lock = {
                timeout = 600;
                command = "noctalia:session lock";
                enabled = true;
              };
              behavior.screen-off = {
                timeout = 660;
                command = "noctalia:dpms-off";
                resume_command = "noctalia:dpms-on";
                enabled = true;
              };
            };

            calendar = {
              enabled = true;
              refresh_minutes = 15;
            };
          }
          // optionalAttrs (config.stylix.enable or false) {
            theme = {
              mode = config.stylix.polarity;
              source = "custom";
              custom_palette = "stylix";
            };
            shell = {
              font = config.stylix.fonts.sansSerif.name;
            };
            theme.templates.enable_builtin_templates = false;
            theme.templates.enable_community_templates = false;
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
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg panel-toggle launcher\")")
            ];
          }
          {
            _args = [
              "SUPER + Tab"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg panel-toggle control-center\")")
            ];
          }
          {
            _args = [
              "SUPER + L"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg session lock\")")
            ];
          }
          {
            _args = [
              "SUPER + P"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg panel-toggle session\")")
            ];
          }
          {
            _args = [
              "SUPER + C"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg panel-toggle launcher /emo\")")
            ];
          }
          {
            _args = [
              "SUPER + V"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg panel-toggle clipboard\")")
            ];
          }
          {
            _args = [
              "XF86AudioMicMute"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg mic-mute\")")
            ];
          }
          # ── Hardware Keys ──────────────────────────────────────────
          {
            _args = [
              "XF86MonBrightnessDown"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg brightness-down\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86MonBrightnessUp"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg brightness-up\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioMute"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg volume-mute\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioLowerVolume"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg volume-down\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioRaiseVolume"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg volume-up\")")
              {
                locked = true;
                repeating = true;
              }
            ];
          }
          {
            _args = [
              "XF86AudioPrev"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg media previous\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioPlay"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg media toggle\")")
              {locked = true;}
            ];
          }
          {
            _args = [
              "XF86AudioNext"
              (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia msg media next\")")
              {locked = true;}
            ];
          }
        ];
      };
    };
  }
