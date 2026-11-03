{
  programs.nvf.settings.vim.languages.terraform = {
    enable = true;
    lsp.servers = [ "tofu-ls" ];
    format = {
      enable = true;
      type = [ "opentofu" ];
    };
  };
}
