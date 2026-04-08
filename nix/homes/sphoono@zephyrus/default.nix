{
  config,
  nvimConfigurations,
  ...
}: {
  imports = [
    ./theme.nix
    ./hypr.nix
    ./userapps.nix
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
      shellAliases = {
        v = "${nvimConfigurations.sphoono}/bin/nvim";
      };
    };

    apps = {
      yazi.enable = true;
      git = {
        enable = true;
        projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
      };
    };
  };
}
