{
  programs.nvf.settings.vim = {
    languages = {
      enableTreesitter = true;
      enableFormat = true;
      enableExtraDiagnostics = true;
    };
    # Formatting is manual only (<leader>lf); the user drives file state.
    lsp.formatOnSave = false;
  };
}
