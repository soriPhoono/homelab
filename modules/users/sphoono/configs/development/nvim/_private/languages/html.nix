{
  programs.nvf.settings.vim.languages.html = {
    enable = true;
    lsp.servers = [ "superhtml" ];
    format = {
      enable = true;
      type = [ "superhtml" ];
    };
    extraDiagnostics = {
      enable = true;
      types = [ "htmlhint" ];
    };
  };
}
