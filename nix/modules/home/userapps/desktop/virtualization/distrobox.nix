{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.userapps.desktop.virtualization.distrobox;
in
  with lib; {
    options.userapps.desktop.virtualization.distrobox = {
      enable = mkEnableOption "Enable distrobox for cross-distro emulation";
      tui.enable = mkEnableOption "Enable distrobox-tui" // {default = true;};
      gui.enable = mkEnableOption "Enable distroshelf GUI" // {default = true;};
    };

    config = mkIf cfg.enable {
      home.packages = with pkgs;
        [
          distrobox
        ]
        ++ optional cfg.tui.enable distrobox-tui
        ++ optional cfg.gui.enable distroshelf;
    };
  }
