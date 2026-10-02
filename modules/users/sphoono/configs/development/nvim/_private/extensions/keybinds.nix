{
  programs.nvf.settings.vim.binds = {
    whichKey = {
      enable = true;
      setupOpts = {
        preset = "modern";
        notify = true;
      };
      register = {
        "<leader>?" = "Cheatsheet";
        "<leader>e" = "Neo-tree";
        "<leader>f" = "+Find";
        "<leader>g" = "+Git";
        "<leader>l" = "+LSP";
      };
    };
    cheatsheet.enable = true;
  };
}
