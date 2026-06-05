{
  pkgs,
  config,
  ...
}: {
  # Enable the framework through the compatibility shim
  personal.hyprland.enable = true;

  # ── Monitor Configuration ──────────────────────────────────────────
  desktop.window-managers.hyprland.monitors = [
    {
      name = "HDMI-A-1";
      primary = true;
      modeline = {
        width = 1920;
        height = 1080;
        refreshRate = 75;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1.0;
    }
  ];

  # ── Autostart Applications ─────────────────────────────────────────
  desktop.xdg.autostart = [
    {
      name = "Vesktop";
      command = "vesktop";
    }
    {
      name = "Steam";
      command = "steam";
    }
  ];

  # ── Noctalia Wallpaper Cache ──────────────────────────────────────
  home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
    defaultWallpaper = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers/default.png";
  };

  # ── Noctalia Shell ─────────────────────────────────────────────────
  desktop.window-managers.hyprland.shells.noctalia = {
    enable = true;
    monitors = ["HDMI-A-1"];
    wallpaperDir = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";
    avatarImage = "${config.home.homeDirectory}/Nextcloud/Pictures/.face";
    location = {
      name = "Fort Worth, TX";
      useFahrenheit = true;
      use12HourFormat = true;
    };
    pluginSettings = {
      usb-drive-manager = {
        autoMount = true;
        hideWhenEmpty = true;
        fileBrowser = "xdg-open";
        terminalCommand = "${pkgs.runapp}/bin/runapp -- ${config.home.sessionVariables.TERMINAL} -e";
      };
      tailscale = {
        showPeerCount = false;
        terminalCommand = "${pkgs.runapp}/bin/runapp -- ${config.home.sessionVariables.TERMINAL} -e";
        taildropReceiveMode = "pkexec";
      };
      pomodoro = {
        workDuration = 25;
        shortBreakDuration = 15;
        longBreakDuration = 15;
        sessionsBeforeLongBreak = 6;
        autoStartBreaks = true;
        autoStartWork = true;
      };
    };
  };
}
