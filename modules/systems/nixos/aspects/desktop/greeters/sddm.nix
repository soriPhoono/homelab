{
  den.aspects.desktop.greeters.sddm = {
    # Theme-neutral: each host picks its own sddm theme.
    nixos =
      { config, ... }:
      {
        services.displayManager.sddm = {
          enable = true;
          wayland.enable = true;
        };
        security.pam.services.sddm.enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;
      };
  };
}
