_: {
  vim.filetree.neo-tree = {
    enable = true;

    setupOpts = {
      # Replace default netrw behavior
      filesystem.hijack_netrw_behavior = "open_default";

      # Git status and diagnostics on files
      enable_git_status = true;
      enable_diagnostics = true;
      git_status_async = true;

      # Visual polish
      hide_root_node = false;
      enable_cursor_hijack = true;
      enable_refresh_on_write = true;
      open_files_in_last_window = false;
    };
  };
}
