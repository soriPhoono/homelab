{
  lib,
  config,
  ...
}: let
  cfg = config.desktop;
in
  with lib; {
    imports = [
      ./hyprland
    ];

    options.desktop.enable = mkEnableOption "desktop";

    config = mkIf cfg.enable {
      services.playerctld.enable = true;
    };
  }
