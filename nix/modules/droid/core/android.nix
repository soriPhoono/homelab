{
  lib,
  config,
  ...
}: let
  cfg = config.core.android;
in
  with lib; {
    options.core.android = {
      enable = mkEnableOption "Enable Android support";
    };

    config = mkIf cfg.enable {
      android-integration = {
        am.enable = true;
        termux-open-url.enable = true;
        xdg-open.enable = true;
        termux-setup-storage.enable = true;
        termux-wake-lock.enable = true;
        termux-wake-unlock.enable = true;
      };

      home-manager.config.imports = [
        ({pkgs, ...}: {
          systemd.user.services.setup-storage = {
            Unit = {
              Description = "Setup Termux storage if missing";
            };
            Service = {
              Type = "oneshot";
              ExecStart = "${pkgs.bash}/bin/bash -c 'if [ ! -e \"$HOME/storage\" ]; then termux-setup-storage; fi'";
              RemainAfterExit = true;
            };
            Install = {
              WantedBy = ["default.target"];
            };
          };

          systemd.user.services.android-wake-lock = {
            Unit = {
              Description = "Acquire Termux wake lock";
            };
            Service = {
              Type = "oneshot";
              ExecStart = "termux-wake-lock";
              ExecStop = "${pkgs.bash}/bin/bash -c 'if [ $(ls /dev/pts | grep -cE \"^[0-9]+$\") -le 1 ]; then termux-wake-unlock; fi'";
              RemainAfterExit = true;
            };
            Install = {
              WantedBy = ["default.target"];
            };
          };
        })
      ];
    };
  }
