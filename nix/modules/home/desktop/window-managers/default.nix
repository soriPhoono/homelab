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

      ./shells
    ];

    options.desktop.window-managers = {
      enable = mkEnableOption "Window manager support for desktop environments";

      variants = mkOption {
        type = with types;
          listOf (enum [
            "hyprland"
            "niri"
          ]);
        default = [];
        description = "The types of window managers to enable customization on for this user profile";
      };

      common = {
        mod = mkOption {
          type = types.str;
          default = "SUPER";
          description = ''
            The primary modifier key used across all window manager keybindings.
            This is passed to the WM config as the mod key for action bindings
            like window focus, workspace switching, and launcher shortcuts.
            Common values: SUPER (also known as Windows/Meta key), ALT.
          '';
        };
      };
    };

    config = mkIf cfg.enable {
      desktop.enable = true;

      # Default session variables for WM users
      home.sessionVariables = {
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
