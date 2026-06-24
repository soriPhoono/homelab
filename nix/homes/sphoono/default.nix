{
  imports = [
    ./configs
    ./theme.nix
  ];

  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yml;
    };

    gpg = {
      enable = true;
      identities.primary.keyFingerprint = "9FB33E455648D323D13BDD75765B1ECF9CACEEB6"; # gitleaks:allow
    };

    email = {
      enable = true;
      accounts = {
        personal = {
          address = "soriphoono@gmail.com";
          primary = true;
        };
      };
    };

    apps.git = {
      enable = true;
      userName = "soriphoono";
      signingProvider = "gpg";
    };
  };
}
