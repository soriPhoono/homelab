{
  den.aspects.desktop.greeters.noctalia.nixos = _: {
    services.displayManager.noctalia-greeter.enable = true;
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
