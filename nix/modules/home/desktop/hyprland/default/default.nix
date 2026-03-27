{
  lib,
  config,
  ...
}: let
  cfg = config.desktop.hyprland.default;
in
  with lib; {
    imports = [
      ./binds
    ];

    options.desktop.hyprland.default = {
      enable =
        (mkEnableOption "Enable default hyprland desktop customizations")
        // {
          default = config.desktop.hyprland.enable;
        };
    };

    config = mkIf cfg.enable {
      wayland.windowManager.hyprland.settings = {
        general = {
          border_size = 3;
          gaps_in = 4;
          gaps_out = 8;
          float_gaps = 8;

          snap.enabled = true;
        };

        decoration = {
          rounding = 10;
        };
      };
    };
  }
