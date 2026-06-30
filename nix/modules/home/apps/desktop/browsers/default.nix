{
  lib,
  config,
  ...
}: let
  cfg = config.apps.desktop.browsers;
in
  with lib; {
    imports = [
      ./zen.nix
      ./firefox.nix
    ];

    options.apps.desktop.browsers.enable = mkEnableOption "Enable browser component configuration";

    config = mkIf cfg.enable {
      services.psd = {
        enable = true;
        resyncTimer = "10m";
      };
    };
  }
