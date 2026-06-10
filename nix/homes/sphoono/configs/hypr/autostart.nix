{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.window-managers.hyprland;
  homepageUrl = "http://127.0.0.1:8082";
in
  with lib; {
    config = mkIf cfg.enable {
      desktop.window-managers.hyprland.autostart = [
        # Wait one second for the session to settle, then open the homepage
        # in the user's default browser (respecting $BROWSER / xdg-settings).
        # With browser.startup.page = 3 set in Zen, the browser will restore
        # previous session tabs AND open this URL in a new tab.
        "bash -c 'sleep 1 && xdg-open ${homepageUrl}'"
      ];
    };
  }
