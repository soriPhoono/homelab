{
  lib,
  config,
  nixosConfig,
  ...
}: let
  cfg = config.desktop.hyprland;
in
  with lib; {
    imports = [
      ./default
    ];

    options.desktop.hyprland = {
      enable = mkEnableOption "Enable hyprland desktop environment.";
    };

    config = mkIf cfg.enable {
      desktop.enable = true;

      xdg.configFile."uwsm/env".source = mkIf (nixosConfig != null && nixosConfig.programs.hyprland.withUWSM) "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

      wayland.windowManager.hyprland.enable = true;
    };
  }
