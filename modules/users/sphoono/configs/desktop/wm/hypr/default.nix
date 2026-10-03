{ lib, ... }: {
  den.aspects.sphoono.desktop.wm.hypr = {
    homeManager =
      {
        nixosConfig ? { },
        ...
      }:
      {
        wayland.windowManager.hyprland = {
          enable = true;

          portal = lib.mkIf (nixosConfig.programs.hyprland.enable or false) null;
          portalPackage = lib.mkIf (nixosConfig.programs.hyprland.enable or false) null;

          systemd.variables = [ "--all" ];
        };
      };
  };
}
