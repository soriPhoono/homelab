{
  lib,
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
      ./data-fortress
      ./office
    ];

    options.userapps = {
      enable = mkEnableOption "Enable core applications and default feature-set";
    };

    config = mkIf cfg.enable {
      services = {
        psd = {
          enable = true;
          resyncTimer = "10m";
        };
      };

      userapps.communication.discord.enable = true;
    };
  }
