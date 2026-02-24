{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps;
in
  with lib; {
    imports = [
      ./browsers
      ./communication
      ./development
    ];

    options.userapps = {
      enable = mkEnableOption "Enable core applications and default feature-set";
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs; [
        nextcloud-client
        bitwarden-desktop
        logseq
        onlyoffice-desktopeditors
      ];

      services = {
        psd = {
          enable = true;
          resyncTimer = "10m";
        };
      };

      userapps.communication.discord.enable = true;
    };
  }
