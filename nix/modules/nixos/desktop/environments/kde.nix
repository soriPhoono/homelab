{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.desktop.environments.kde;
in
  with lib; {
    options.desktop.environments.kde = {
      enable = mkEnableOption "Enable kde desktop environment";
    };

    config = mkIf cfg.enable {
      desktop = {
        enable = true;
        environment = "kde";
        environments.display_managers.sddm.enable = true;
      };

      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
        };

        systemPackages = with pkgs;
        with kdePackages; [
          discover
          ksystemlog

          wallpaper-engine-plugin

          kcolorchooser

          dragon
          elisa

          ktorrent
          kmail

          kwave
          krita
          kdenlive
        ];
      };

      services.desktopManager.plasma6.enable = true;

      home-manager.users =
        lib.mapAttrs (_: _: {
          home.sessionVariables = {
            SSH_AUTH_SOCK = mkDefault "$XDG_RUNTIME_DIR/ssh-agent";
            SSH_ASKPASS = mkDefault "ksshaskpass";
            GIT_ASKPASS = mkDefault "ksshaskpass";
          };
        })
        config.core.users;
    };
  }
