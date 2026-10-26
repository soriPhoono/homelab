{
  # Experimental: treesitter-highlighted completion menu items, wired
  # into blink-cmp via the `completion.menu.draw` block in
  # blink-cmp.nix. If it's too noisy next to blink-cmp's own icons,
  # delete this file and that block together to revert.
  programs.nvf.settings.vim.ui.colorful-menu-nvim.enable = true;
}
