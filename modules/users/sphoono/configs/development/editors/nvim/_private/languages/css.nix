{
  programs.nvf.settings.vim.languages.css = {
    enable = true;
    lsp.servers = [
      "vscode-css-language-server"
      "emmet-ls"
    ];
    format = {
      enable = true;
      type = [ "prettier" ];
    };
  };
}
