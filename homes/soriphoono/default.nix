{pkgs, ...}: {
  core = {
    git = {
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
    };
  };

  userapps.development.agents.gemini = {
    enable = true;
    enableJules = true;
  };

  userapps.development.editors.neovim.settings = (import ./nvim) {inherit pkgs;};
}
