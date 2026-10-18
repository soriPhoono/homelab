{ den, lib, ... }: {
  den.aspects.desktop.managers.hyprland = {
    includes = [
      den.aspects.desktop

      den.aspects.desktop.xdg.portals.gtk
    ];
    nixos =
      { pkgs, ... }:
      {
        programs.hyprland = {
          enable = true;
          withUWSM = true;
        };

        # DDC/CI brightness for external monitors. The ddcutil udev rules grant
        # the active seat access to the GPU-attached i2c buses, so no group
        # membership is needed.
        hardware.i2c.enable = true;
        services.udev.packages = [ pkgs.ddcutil ];
        environment.systemPackages = [ pkgs.ddcutil ];
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
