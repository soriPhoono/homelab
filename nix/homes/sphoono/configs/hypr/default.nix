{
  lib,
  config,
  ...
}: let
  framework = config.desktop;
in
  with lib; {
    imports = [
      ./animations.nix
      ./autostart.nix
    ];

    # Compatibility shim: enabling personal.hyprland delegates to the framework
    options.personal.hyprland.enable = mkEnableOption "Enable Hyprland configuration (framework)";

    config = mkIf (config.personal.hyprland.enable or framework.window-managers.hyprland.enable) {
      # Activate the full desktop environment framework stack
      desktop = {
        enable = true;
        window-managers = {
          enable = true;
          hyprland.enable = true;
        };
      };
    };
  }
