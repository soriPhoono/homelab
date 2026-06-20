{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.services.flatpak;
in
  with lib; {
    options.desktop.services.flatpak.enable = mkEnableOption "Enable Flatpak application containerisation system";

    config = mkIf cfg.enable (mkMerge [
      {
        services.flatpak.enable = true;

        systemd.services = {
          flatpak-configure-flathub = {
            description = "Configure Flathub remote";
            wantedBy = ["multi-user.target"];
            wants = ["network-online.target"];
            # There is no flatpak.service in nixpkgs; wait for D-Bus so SystemHelper can start.
            after = [
              "network-online.target"
              "dbus.service"
            ];
            requires = ["dbus.service"];
            serviceConfig = {
              Type = "oneshot";
              RemainAfterExit = true;
              Restart = "on-failure";
              RestartSec = "5s";
              StartLimitBurst = 3;
              ExecStart = "${pkgs.writeShellApplication {
                name = "configure-flathub";
                runtimeInputs = with pkgs; [
                  flatpak
                ];
                text = ''
                  exec flatpak remote-add --system --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
                '';
              }}/bin/configure-flathub";
            };
          };
        };
      }
    ]);
  }
