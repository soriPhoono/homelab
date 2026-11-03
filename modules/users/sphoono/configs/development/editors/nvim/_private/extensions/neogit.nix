_: {
  programs.nvf.settings.vim.git.neogit = {
    enable = true;
    # The defaults <leader>gs and <leader>gc belong to the telescope git pickers.
    mappings = {
      open = "<leader>gn";
      commit = "<leader>gC";
    };
  };
}
