{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.window-managers;
in
  with lib; {
    imports = [
      ./hyprland
    ];

    options.desktop.window-managers = {
      enable = mkEnableOption "Window manager support for desktop environments";

      common = {
        mod = mkOption {
          type = types.str;
          default = "SUPER";
          description = "Modifier key for window manager keybindings (e.g. SUPER, ALT).";
        };

        terminal = mkOption {
          type = types.str;
          description = "Default terminal emulator command.";
          example = "ghostty";
        };

        launcher = mkOption {
          type = types.str;
          default = "rofi -show drun";
          description = "Application launcher command.";
        };

        screenshot = {
          tool = mkOption {
            type = types.enum ["grimblast" "grim" "slurp"];
            default = "grimblast";
            description = "Screenshot tool to use.";
          };
          notify = mkOption {
            type = types.bool;
            default = true;
            description = "Whether to show notifications for screenshots.";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      # Default session variables for WM users
      home.sessionVariables = {
        XDG_CURRENT_DESKTOP = mkOverride 500 "wlroots";
        XDG_SESSION_TYPE = mkOverride 500 "wayland";
        XDG_SESSION_DESKTOP = mkOverride 500 "hyprland";
        NIXOS_OZONE_WL = mkOverride 500 "1";
        _JAVA_AWT_WM_NONREPARENTING = mkOverride 500 "1";
        GDK_BACKEND = mkOverride 500 "wayland";
        CLUTTER_BACKEND = mkOverride 500 "wayland";
        MOZ_ENABLE_WAYLAND = mkOverride 500 "1";
        MOZ_WEBRENDER = mkOverride 500 "1";
        QT_WAYLAND_DISABLE_WINDOWDECORATION = mkOverride 500 "1";
        QT_QPA_PLATFORM = mkOverride 500 "wayland;xcb";
        SDL_VIDEO_DRIVER = mkOverride 500 "wayland";
        _JAVA_OPTIONS = mkOverride 500 "-Dawt.toolkit.name=WLToolkit";
      };
    };
  }
