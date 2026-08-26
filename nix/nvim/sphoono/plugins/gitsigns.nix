_: {
  vim.git.gitsigns = {
    enable = true;

    setupOpts = {
      current_line_blame = false;
      sign_priority = 6;
      update_debounce = 100;
    };
  };
}
