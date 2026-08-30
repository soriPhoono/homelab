_: {
  vim.lsp.trouble = {
    enable = true;

    mappings = {
      # Telescope already owns <leader>lr for LSP references.
      lspReferences = null;
    };
  };
}
