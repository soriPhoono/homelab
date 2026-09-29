{ den, lib, ... }: {
  den.aspects.desktop.managers.hyprland = {
    includes = [
      den.aspects.desktop

      den.aspects.desktop.xdg-portal.gtk
    ];
    nixos.programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    homeManager = { config, nixosConfig, ... }: {
      xdg.configFile."uwsm/env".source =
        lib.mkIf nixosConfig.programs.uwsm.enable "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
      desktop.window-managers.hyprland.enable = true;
    };
  };
}
