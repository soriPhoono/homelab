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
        # The greeter's home: last user and session.
        environment.persistence."/persist".directories = [
          {
            directory = "/var/lib/sddm";
            user = "sddm";
            group = "sddm";
            mode = "0700";
          }
        ];
      };
  };
}
