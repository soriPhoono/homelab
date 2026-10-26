{
  programs.nvf.settings.vim.languages.rust = {
    enable = true;
    lsp.servers = [ "rust-analyzer" ];
    format = {
      enable = true;
      type = [ "rustfmt" ];
    };
    # rustaceanvim is off: nvf asserts it is mutually exclusive with dap.enable.
    extensions.crates-nvim.enable = true;
  };
}
