_: {
  programs.nvf.settings.vim.terminal.toggleterm = {
    enable = true;
    # <C-t> toggles in normal and terminal mode; a count such as 2<C-t> opens a
    # second terminal.
    setupOpts = {
      direction = "float";
      float_opts.border = "curved";
    };
  };
}
