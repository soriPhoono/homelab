{
  # Stylix auto-targets nvf with a generic base16 colorscheme, which
  # conflicts with the real catppuccin.nvim plugin and its transparency
  # and per-plugin integrations (bufferline, alpha, telescope, ...) set
  # up below.
  stylix.targets.nvf.enable = false;

  programs.nvf.settings.vim.theme = {
    enable = true;
    name = "catppuccin";
    style = "macchiato";
    transparent = true;
  };
}
