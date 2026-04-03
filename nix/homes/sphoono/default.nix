{nvimConfigurations, ...}: {
  core = {
    secrets.defaultSopsFile = ./secrets.yml;

    apps.git.userName = "soriphoono";

    shells.shellAliases = {
      v = "${nvimConfigurations.sphoono}/bin/nvim";
    };
  };

  userapps.development.editors.neovim = {
    enable = true;
    package = nvimConfigurations.sphoono;
  };
}
