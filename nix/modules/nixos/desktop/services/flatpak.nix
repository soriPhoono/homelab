{
  lib,
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

      systemd.services."flatpak-install-warehouse" = mkIf cfg.enableStore {
        description = "Install Warehouse Flatpak";
        after = ["flatpak.service"];
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.writers.writeShellApplication {
            name = "install-warehouse-flatpak";
            text = ''
              flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
              flatpak install -y flathub io.github.mimbrero.Warehouse
            '';
          }}";
        };
      };
    };
  }
