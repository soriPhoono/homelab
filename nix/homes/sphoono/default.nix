{nvimConfigurations, ...}: {
  core = {
    git = {
      enable = true;
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
    };
  };

  userapps.development.editors.neovim = {
    enable = true;
    package = nvimConfigurations.sphoono;
  };
}
