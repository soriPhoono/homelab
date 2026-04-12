{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.desktop.browsers;
in
  with lib; {
    imports = [
      ./zen.nix
      ./firefox.nix
    ];

    options.userapps.desktop.browsers.enable = mkEnableOption "Enable browser component configuration";

    config = mkIf cfg.enable {
      services.psd = {
        enable = true;
        resyncTimer = "10m";
      };
    };
  }
