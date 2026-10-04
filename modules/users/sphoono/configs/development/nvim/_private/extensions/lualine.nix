{
  programs.nvf.settings.vim.statusline.lualine = {
    enable = true;
    setupOpts.options = {
      theme = "auto";
      globalstatus = true;
      icons_enabled = true;
      disabled_filetypes.statusline = [
        "alpha"
        "neo-tree"
        "TelescopePrompt"
      ];
    };
  };
}
