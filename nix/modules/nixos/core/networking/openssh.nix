{
  programs.ssh.startAgent = true;

  services.openssh = {
    enable = true;
    settings = {
      UseDns = true;
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
}
