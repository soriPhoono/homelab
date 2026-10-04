{ den, lib, ... }: {
  den.aspects.desktop.managers.hyprland = {
    includes = [
      den.aspects.desktop

      den.aspects.desktop.xdg.portals.gtk
    ];
    nixos.programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    homeManager =
      {
        config,
        osConfig ? { },
        pkgs,
        ...
      }:
      {
        services.gpg-agent.pinentry.package = pkgs.pinentry-gnome3;
        xdg.configFile."uwsm/env".source = lib.mkIf (osConfig.programs.uwsm.enable or false
        ) "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";
        wayland.windowManager.hyprland.enable = true;
      };
  };
}
