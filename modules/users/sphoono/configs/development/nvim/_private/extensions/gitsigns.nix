{
  programs.nvf.settings.vim.git.gitsigns = {
    enable = true;
    # The defaults put these under <leader>t, which is the Test group.
    mappings = {
      toggleBlame = "<leader>hB";
      toggleDeleted = "<leader>hx";
    };
    setupOpts = {
      current_line_blame = false;
      sign_priority = 6;
      update_debounce = 100;
    };
  };
}
