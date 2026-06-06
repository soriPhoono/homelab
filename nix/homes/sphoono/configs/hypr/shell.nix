{
  lib,
  pkgs,
  config,
  ...
}: let
  hyprCfg = config.desktop.window-managers.hyprland;
in
  with lib; {
    config = mkIf hyprCfg.enable {
      desktop.window-managers.shells.noctalia = {
        enable = true;

        avatarImage = ../assets/avatar.png;

        wallpaperDir = "${config.home.homeDirectory}/Nextcloud/Pictures/Wallpapers";

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
    };
  }
