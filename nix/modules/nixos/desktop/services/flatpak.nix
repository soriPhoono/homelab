{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.services.flatpak;
in
  with lib; {
    options.desktop.services.flatpak = {
      enable = mkEnableOption "Enable Flatpak application containerisation system";

      enableStore =
        mkEnableOption "Enable Flatpak store setup with Warehouse app"
        // {
          default = config.desktop.environment == null;
        };
    };

    config = mkIf cfg.enable {
      services.flatpak.enable = true;

      systemd.services = {
        flatpak-configure-flathub = {
          description = "Configure Flathub remote";
          wants = ["network-online.target"];
          after = ["network-online.target" "flatpak.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellApplication {
              name = "configure-flathub";
              runtimeInputs = with pkgs; [
                flatpak
              ];
              text = ''
                flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
              '';
            }}/bin/configure-flathub";
          };
        };
      };
    };
  }
