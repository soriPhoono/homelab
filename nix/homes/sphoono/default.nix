{nvimConfigurations, ...}: {
  imports = [
    ./configs
  ];

  core = {
    shells.bash.enable = true;

    secrets.defaultSopsFile = ./secrets.yml;
    apps.git.userName = "soriphoono";
  };

  userapps.development.editors.neovim = {
    package = nvimConfigurations.sphoono;
  };
}
