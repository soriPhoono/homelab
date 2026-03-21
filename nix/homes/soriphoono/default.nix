{pkgs, ...}: {
  core = {
    secrets = {
      enable = true;
      defaultSopsFile = ./secrets.yaml;
    };

    git = {
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
    };
  };

  userapps.development.editors.neovim.settings = import ./nvim {inherit pkgs;};
}
