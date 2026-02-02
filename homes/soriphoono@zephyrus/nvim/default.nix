{
  imports = [
    ./plugins
  ];

  programs.nvf = {
    enable = true;

    settings.vim = {
      viAlias = true;
      vimAlias = true;

      bell = "on";
      hideSearchHighlight = true;

      globals = {
        mapleader = " ";
        maplocalleader = " ";
      };

      options = {
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;

        foldenable = false;
        wrap = false;
      };

      git.enable = true;
      undoFile.enable = true;
      theme.enable = true;
    };
  };
}
