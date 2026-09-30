{
  den.aspects.desktop.greeters.sddm = {
    nixos = { config, ... }: {
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      security.pam.services.sddm.enableGnomeKeyring = config.services.gnome.gnome-keyring.enable;
    };
  };
}
