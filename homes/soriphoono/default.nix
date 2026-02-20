{pkgs, ...}: {
  core = {
    git = {
      userName = "soriphoono";
      userEmail = "soriphoono@gmail.com";
    };
  };

  userapps.development.editors.neovim.settings = (import ./nvim) {inherit pkgs;};
}
