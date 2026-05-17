{
  inputs,
  lib,
  pkgs,
  config,
  nixosConfig ? null,
  ...
}: let
  framework = config.userapps.desktop.environments;
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
      userapps.desktop.environments = {
        enable = true;
        window-managers = {
          enable = true;
          hyprland.enable = true;
          hyprland = {
            package = mkIf (nixosConfig != null) (mkDefault inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland);
            portalPackage = mkIf (nixosConfig != null) (mkDefault inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland);
          };
        };
      };
    };
  }
