{
  programs.nvf.settings.vim.languages.yaml = {
    enable = true;
    lsp.servers = [ "yaml-language-server" ];
    format = {
      enable = true;
      type = [ "prettier" ];
    };
  };
}
