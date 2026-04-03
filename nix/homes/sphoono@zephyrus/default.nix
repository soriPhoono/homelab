{config, ...}: {
  imports = [
    ./hypr

    ./userapps.nix
    ./theme.nix
  ];

  core = {
    secrets.enable = true;

    email = {
      enable = true;
      accounts = {
        personal = {
          address = "soriphoono@gmail.com";
          primary = true;
        };
      };
    };

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };

    apps = {
      yazi.enable = true;
      git = {
        enable = true;
        projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
      };
      development.enable = true;
    };
  };
}
