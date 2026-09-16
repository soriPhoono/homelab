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
      identities = {
        primary.keyFingerprint = "BB20833A2AFD3CA979BCAE320C572D55C04518CF";
      };
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

    apps = {
      git = {
        enable = true;
        userName = "soriphoono";
        signingProvider = "gpg";
      };
    };

    shells = {
      shellAliases = {
        gs = "git status";
        ga = "git add";
        gc = "git commit -m";
        gch = "git checkout -b";
        gp = "git push";
        gpl = "git pull";
      };
      starship.enable = true;
      fastfetch.enable = true;
    };
  };
}
