{nvimConfigurations, ...}: {
  imports = [
    ./opencode
  ];

  core = {
    secrets.defaultSopsFile = ./secrets.yml;
    shells.bash.enable = true;

    apps.git.userName = "soriphoono";
  };

  userapps.development.editors.neovim = {
    package = nvimConfigurations.sphoono;
  };
}
