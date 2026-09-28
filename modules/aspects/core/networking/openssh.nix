{
  den.aspects.core.networking.openssh = {
    nixos = {
      services.openssh = {
        enable = true;
        settings = {
          UseDns = true; # ASK
          PermitRootLogin = "no";
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
        };
      };
    };
  };
}
