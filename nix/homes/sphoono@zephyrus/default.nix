{config, ...}: {
  imports = [
    ./userapps.nix
    ./theme.nix

    ./hypr
  ];

  core = {
    secrets = {
      enable = true;
      environment = {
        enable = true;
        sopsFile = ./secrets.env;
      };
    };

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };

    apps.yazi.enable = true;

    git.projectsDir = "${config.home.homeDirectory}/Documents/Projects/";
  };
}
