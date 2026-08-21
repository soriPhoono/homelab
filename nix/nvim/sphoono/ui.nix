_: {
  vim = {
    # Floating-window chrome
    ui = {
      borders = {
        enable = true;
        globalStyle = "rounded";
      };

      # Better cmdline, messages, popupmenu
      noice = {
        enable = true;
        setupOpts.lsp.signature.enabled = true;
      };

      # Code-context breadcrumbs (navic) rendered in the winbar
      breadcrumbs = {
        enable = true;
        lualine.winbar.enable = true;
        navbuddy.enable = true;
      };

      # Highlight the word under the cursor
      illuminate.enable = true;

      # Color code highlighting (hex, rgb, named colors)
      nvim-highlight-colors.enable = true;

      # Code-action popup, better than the default menu
      fastaction.enable = true;
    };

    # Notifications routed through nvim-notify (picked up by noice)
    notify.nvim-notify.enable = true;

    visuals = {
      # File-type icons for statusline, breadcrumbs, pickers
      nvim-web-devicons.enable = true;

      # LSP progress in the corner
      fidget-nvim.enable = true;

      # Indent guides
      indent-blankline.enable = true;

      # Colored matching brackets
      rainbow-delimiters.enable = true;

      # Flash on undo/redo so the change is visible
      highlight-undo.enable = true;

      # Scrollbar with search/diagnostic markers
      nvim-scrollbar.enable = true;
    };
  };
}
