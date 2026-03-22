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
          after = ["flatpak.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellApplication {
              name = "configure-flathub";
              text = ''
                flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
              '';
            }}/bin/configure-flathub";
          };
        };

        flatpak-install-warehouse = mkIf cfg.enableStore {
          description = "Install Warehouse Flatpak";
          after = ["flatpak-configure-flathub.service"];
          wantedBy = ["multi-user.target"];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellApplication {
              name = "install-warehouse-flatpak";
              text = ''
                flatpak install -y flathub io.github.mimbrero.Warehouse
              '';
            }}/bin/install-warehouse-flatpak";
          };
        };
      };
    };
  }
