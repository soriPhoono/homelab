{
  imports = [
    ./configs

    ./theme.nix
  ];

  core = {
    secrets.defaultSopsFile = ./secrets.yml;

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
    };
  };
}
