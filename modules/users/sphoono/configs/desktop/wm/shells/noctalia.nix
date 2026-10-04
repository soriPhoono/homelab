# Noctalia v5: bar, launcher, notifications, OSD, lock screen, idle, wallpaper
# and screenshots. Settings here are the declarative base layer; anything
# changed in the GUI lands in ~/.local/state/noctalia/settings.toml and wins.
# Colours, theme mode and font come from the Stylix noctalia target.
#
# Each compositor's integration (autostart, keybinds, layer rules) lives in a
# guarded block below, so this aspect stays usable from any window manager.
{ lib, ... }:
let
  toLua = lib.generators.toLua { };
in
{
  den.aspects.sphoono.desktop.wm.shells.noctalia = {
    homeManager =
      { config, pkgs, ... }:
      let
        noctalia = lib.getExe config.programs.noctalia.package;
        msg = command: lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua "${noctalia} msg ${command}"})";
        bind = keys: command: {
          _args = [
            keys
            (msg command)
          ];
        };
        bindWith = keys: command: opts: {
          _args = [
            keys
            (msg command)
            opts
          ];
        };
        locked = {
          locked = true;
        };
        lockedRepeating = {
          locked = true;
          repeating = true;
        };
      in
      {
        # The Stylix target writes only a dark variant of its palette, but maps
        # the default "either" polarity to light mode, which that palette lacks.
        stylix.targets.noctalia.polarity.override = "dark";

        programs.noctalia = {
          enable = true;
          settings = {
            shell = {
              time_format = "{:%I:%M %p}";
              date_format = "%A, %x";
              show_location = true;
              clipboard_enabled = true;
              password_style = "default";
              settings_show_advanced = false;
              # Noctalia runs under uwsm, so launched apps get their own units
              # and survive a shell restart.
              launch_apps_as_systemd_services = true;

              panel = {
                transparency_mode = "glass";
                borders = true;
                launcher_placement = "floating";
                clipboard_placement = "floating";
                control_center_placement = "attached";
                session_placement = "attached";
              };

              # Restating the default five actions; logout goes through uwsm so
              # the session's units stop cleanly.
              session.actions = [
                { action = "lock"; }
                {
                  action = "logout";
                  command = "${lib.getExe pkgs.uwsm} stop";
                }
                { action = "lock_and_suspend"; }
                { action = "reboot"; }
                {
                  action = "shutdown";
                  variant = "destructive";
                }
              ];
            };

            wallpaper = {
              enabled = true;
              directory = "${config.home.homeDirectory}/Shared/Pictures/Wallpapers";
            };

            bar.main = {
              position = "top";
              background_opacity = 0.9;
              radius = 12;
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
              center = [ "media" ];
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

            dock.enabled = false;

            notification = {
              enable_daemon = true;
              show_app_name = true;
              show_actions = true;
              layer = "top";
              scale = 1.0;
              offset_x = 20;
              offset_y = 8;
            };

            osd = {
              position = "top_right";
              orientation = "horizontal";
              scale = 1.0;
              offset_x = 20;
              offset_y = 8;
              kinds = {
                volume = true;
                volume_output = true;
                volume_input = true;
                brightness = true;
                keyboard_backlight = true;
                wifi = true;
                bluetooth = true;
                power_profile = true;
                caffeine = true;
                dnd = true;
                lock_keys = true;
                keyboard_layout = true;
              };
            };

            lockscreen = {
              blurred_desktop = true;
              blur_intensity = 0.5;
              tint_intensity = 0.3;
            };

            system.monitor = {
              enabled = true;
              cpu_poll_seconds = 2.0;
              gpu_poll_seconds = 5.0;
              memory_poll_seconds = 2.0;
              network_poll_seconds = 3.0;
              disk_poll_seconds = 10.0;
            };

            audio = {
              enable_overdrive = false;
              enable_sounds = true;
              sound_volume = 0.5;
            };

            nightlight = {
              enabled = true;
              force = false;
              temperature_day = 6500;
              temperature_night = 4000;
            };

            idle = {
              behavior_order = [
                "lock"
                "screen-off"
              ];
              behavior = {
                lock = {
                  action = "lock";
                  timeout = 600;
                  enabled = true;
                };
                screen-off = {
                  action = "screen_off";
                  timeout = 660;
                  enabled = true;
                };
              };
            };

            calendar = {
              enabled = true;
              refresh_minutes = 15;
            };

            # Stylix themes the other applications; noctalia's own templates
            # would fight it.
            theme.templates = {
              enable_builtin_templates = false;
              enable_community_templates = false;
            };
          };
        };

        wayland.windowManager.hyprland.settings = lib.mkIf config.wayland.windowManager.hyprland.enable {
          on = [
            {
              _args = [
                "hyprland.start"
                (lib.generators.mkLuaInline ''
                  function()
                    hl.exec_cmd(${toLua "${lib.getExe pkgs.uwsm} app -- ${noctalia}"})
                  end'')
              ];
            }
          ];

          layer_rule = [
            {
              name = "noctalia";
              match.namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$";
              no_anim = true;
              ignore_alpha = 0.5;
              blur = true;
              blur_popups = true;
            }
            {
              match.namespace = "noctalia:regionSelector";
              no_anim = true;
            }
          ];

          # The settings window is noctalia's own, not an application rule.
          window_rule = [
            {
              match.class = "dev.noctalia.Noctalia";
              float = true;
              size = [
                1080
                920
              ];
            }
          ];

          bind = [
            # -- Shell surfaces --
            (bind "SUPER + A" "panel-toggle launcher")
            (bind "SUPER + Tab" "panel-toggle control-center")
            (bind "SUPER + V" "panel-toggle clipboard")
            (bind "SUPER + Escape" "panel-toggle session")
            (bind "SUPER + Space" "session lock")
            (bind "ALT + Tab" "window-switcher hold")

            # -- Screenshots --
            (bind "Print" "screenshot-fullscreen monitor")
            (bind "SUPER + Print" "screenshot-region")
            (bind "SUPER + SHIFT + Print" "screenshot-annotate")

            # -- Hardware keys --
            (bindWith "XF86AudioRaiseVolume" "volume-up" lockedRepeating)
            (bindWith "XF86AudioLowerVolume" "volume-down" lockedRepeating)
            (bindWith "XF86AudioMute" "volume-mute" locked)
            (bindWith "XF86AudioMicMute" "mic-mute" locked)
            (bindWith "XF86MonBrightnessUp" "brightness-up" lockedRepeating)
            (bindWith "XF86MonBrightnessDown" "brightness-down" lockedRepeating)
            (bindWith "XF86KbdBrightnessUp" "keyboard-backlight-up" lockedRepeating)
            (bindWith "XF86KbdBrightnessDown" "keyboard-backlight-down" lockedRepeating)
            (bindWith "XF86AudioPlay" "media toggle" locked)
            (bindWith "XF86AudioPrev" "media previous" locked)
            (bindWith "XF86AudioNext" "media next" locked)
          ];
        };
      };
  };
}
