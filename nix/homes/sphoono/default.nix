{nvimConfigurations, ...}: {
  core = {
    secrets.defaultSopsFile = ./secrets.yml;

    git = {
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
    };
  };

  userapps.development.editors.neovim = {
    enable = true;
    package = nvimConfigurations.sphoono;
  };
}
