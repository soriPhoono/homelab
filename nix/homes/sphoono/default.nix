{nvimConfigurations, ...}: {
  imports = [
    ./opencode
  ];

  core = {
    secrets.defaultSopsFile = ./secrets.yml;

    apps.git = {
      enable = true;
      userName = "soriphoono";
    };

    shells.shellAliases = {
      v = "${nvimConfigurations.sphoono}/bin/nvim";
    };
  };

  userapps.development.editors.neovim = {
    enable = true;
    package = nvimConfigurations.sphoono;
  };
}
