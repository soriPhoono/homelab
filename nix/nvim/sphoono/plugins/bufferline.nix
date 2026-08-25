_: {
  vim.tabline.nvimBufferline = {
    enable = true;

    mappings = {
      closeCurrent = "<leader>bd";
      cycleNext = null;
      cyclePrevious = null;
      pick = "<leader>bb";
    };

    setupOpts = {
      options = {
        mode = "buffers";
        diagnostics = "nvim_lsp";
        separator_style = "slant";
        always_show_bufferline = true;
        show_buffer_close_icons = true;
      };
    };
  };
}
