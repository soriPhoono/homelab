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

    shells.shellAliases.v = "nvim";
  };

  userapps = {
    development = {
      editors.neovim = {
        enable = true;
        settings = import ./nvim {inherit pkgs;};
      };
      agents = {
        gemini = {
          enable = true;
          enableJules = true;
        };
        claude.enable = true;
      };
    };
  };
}
