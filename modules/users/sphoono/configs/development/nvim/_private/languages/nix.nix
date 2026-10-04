{
  programs.nvf.settings.vim.languages.nix = {
    enable = true;
    lsp.servers = [ "nil" ];
    format = {
      enable = true;
      # Matches the nixfmt treefmt uses on this repo (flake-system/treefmt.nix).
      type = [ "nixfmt" ];
    };
    extraDiagnostics.enable = true;
  };
}
