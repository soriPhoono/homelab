{
  lib,
  pkgs,
  config,
  ...
}: {
  # Enable the framework through the compatibility shim
  personal.hyprland.enable = true;

  # ── Monitor Configuration ──────────────────────────────────────────
  desktop.window-managers.hyprland.monitors = [
    {
      name = "eDP-1";
      primary = true;
      modeline = {
        width = 1920;
        height = 1080;
        refreshRate = 144;
      };
      position = {
        x = 0;
        y = 0;
      };
      scale = 1.25;
    }
  ];

  # ── Autostart Applications ─────────────────────────────────────────
  desktop.xdg.autostart = [
    {
      name = "Vesktop";
      command = "vesktop";
    }
    {
      name = "Zen Browser";
      command = "zen-twilight & sleep 5 && xdg-open 'https://messages.google.com/web' && xdg-open 'https://gemini.google.com' && xdg-open 'https://media.local.cryptic-coders.net/watch'";
      delay = "5s";
    }
  ];

  # ── ROG-Specific Binds ─────────────────────────────────────────────
  desktop.window-managers.hyprland.settings = {
    bind = [
      # ROG Key → Settings
      {
        _args = [
          "XF86Launch1"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call settings toggle\")")
        ];
      }
      # Fan Mode
      {
        _args = [
          "XF86Launch4"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call powerProfile cycle\")")
        ];
      }
      # Airplane Mode
      {
        _args = [
          "XF86Launch5"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"noctalia-shell ipc call airplaneMode toggle\")")
        ];
      }
      # Keyboard Brightness
      {
        _args = [
          "XF86KbdBrightnessDown"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%-\")")
        ];
      }
      {
        _args = [
          "XF86KbdBrightnessUp"
          (lib.generators.mkLuaInline "hl.dsp.exec_cmd(\"${pkgs.brightnessctl}/bin/brightnessctl -d asus::kbd_backlight set 33%+\")")
        ];
      }
    ];
  };

  # ── Noctalia Wallpaper Cache ──────────────────────────────────────
  home.file.".cache/noctalia/wallpapers.json".text = builtins.toJSON {
    defaultWallpaper = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers/default.png";
  };

  # ── Noctalia Shell ─────────────────────────────────────────────────
  desktop.window-managers.hyprland.shells.noctalia = {
    enable = true;
    monitors = ["eDP-1"];
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
        terminalCommand = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e";
      };
      tailscale = {
        showPeerCount = false;
        terminalCommand = "${pkgs.run-application}/bin/run-application ${config.home.sessionVariables.TERMINAL} -e";
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
