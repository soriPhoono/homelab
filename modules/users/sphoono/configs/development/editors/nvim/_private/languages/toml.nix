{
  programs.nvf.settings.vim.languages.toml = {
    enable = true;
    lsp.servers = [ "taplo" ];
    format = {
      enable = true;
      type = [ "taplo" ];
    };
    # The taplo language server already reports diagnostics.
    extraDiagnostics.enable = false;
  };
}
