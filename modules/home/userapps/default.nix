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

        discord
      ];

      services = {
        psd = {
          enable = true;
          resyncTimer = "10m";
        };
      };
    };
  }
