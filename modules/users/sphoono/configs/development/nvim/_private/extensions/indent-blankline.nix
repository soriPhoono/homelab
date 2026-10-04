{
  programs.nvf.settings.vim.visuals.indent-blankline = {
    enable = true;
    setupOpts = {
      indent = {
        char = "│";
        highlight = "Whitespace";
      };
      # VSCode-style guides: one flat, muted colour throughout, no
      # treesitter-scope highlight or start/end underlines.
      scope.enabled = false;
    };
  };
}
