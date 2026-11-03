_: {
  programs.nvf.settings.vim = {
    visuals.fidget-nvim.enable = true;

    # fidget shows LSP progress; noice would duplicate it as toasts.
    ui.noice.setupOpts.lsp.progress.enabled = false;
  };
}
