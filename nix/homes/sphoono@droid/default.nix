{config, ...}: {
  imports = [
    ./theme.nix
  ];

  core = {
    secrets.enable = true;

    shells = {
      fish.generateCompletions = true;
      starship.enable = true;
      fastfetch.enable = true;
    };

    apps = {
      git.projectsDir = "${config.home.homeDirectory}/projects/";
    };
  };

  userapps.development.agents.opencode.enable = true;
}
