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

        # Line numbers
        number = true;
        relativenumber = true;

        # Visual aids
        cursorline = true;
        scrolloff = 8;
        sidescrolloff = 8;
        signcolumn = "yes";

        # Split behavior
        splitright = true;
        splitbelow = true;

        # Search
        ignorecase = true;
        smartcase = true;

        # System clipboard
        clipboard = "unnamedplus";

        # Mouse support
        mouse = "a";
      };

      git.enable = true;
      undoFile.enable = true;
      theme.enable = true;
    };
  };
}
