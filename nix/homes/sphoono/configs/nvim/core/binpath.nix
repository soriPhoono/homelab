{pkgs, ...}: {
  # Add tree-sitter CLI to neovim's PATH for nvim-treesitter healthcheck
  mnw.extraBinPath = [pkgs.tree-sitter];
}
