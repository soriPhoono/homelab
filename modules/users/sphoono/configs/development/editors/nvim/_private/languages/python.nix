{
  programs.nvf.settings.vim.languages.python = {
    enable = true;
    # pyright for types, the ruff server for lint diagnostics and code actions.
    lsp.servers = [
      "pyright"
      "ruff"
    ];
    format = {
      enable = true;
      # Matches templates#python: ruff check (extend-select I) then ruff format.
      type = [
        "ruff-fix"
        "ruff"
      ];
    };
    extraDiagnostics = {
      enable = true;
      types = [ "mypy" ];
    };
  };
}
