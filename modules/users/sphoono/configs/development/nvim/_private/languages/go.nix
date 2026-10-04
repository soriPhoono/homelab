{
  programs.nvf.settings.vim.languages.go = {
    enable = true;
    lsp.servers = [ "gopls" ];
    format = {
      enable = true;
      type = [
        "goimports"
        "gofumpt"
      ];
    };
    extraDiagnostics = {
      enable = true;
      types = [ "golangci-lint" ];
    };
  };
}
