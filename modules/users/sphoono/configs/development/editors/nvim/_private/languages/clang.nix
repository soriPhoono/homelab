{
  programs.nvf.settings.vim.languages.clang = {
    enable = true;
    lsp.servers = [ "clangd" ];
    format = {
      enable = true;
      type = [ "clang-format" ];
    };
    extraDiagnostics = {
      enable = true;
      types = [ "clangtidy" ];
    };
  };
}
