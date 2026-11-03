{
  programs.nvf.settings.vim.languages.json = {
    enable = true;
    lsp.servers = [ "vscode-json-language-server" ];
    format = {
      enable = true;
      type = [ "prettier" ];
    };
  };
}
