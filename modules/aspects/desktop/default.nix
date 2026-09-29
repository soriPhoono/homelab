{
  den.aspects.desktop.nixos = {
    sessionVariables.NIXOS_OZONE_WL = "1";
    security.polkit.enable = true;
    services = {
      power-profiles-daemon.enable = true;
      upower.enable = true;
      geoclue2.enable = true;
    };
  };
}
