_: {
  vim.filetree.neo-tree = {
    enable = true;

    setupOpts = {
      # Use rounded borders for Neo-tree floats and its input popups.
      popup_border_style = "rounded";
      window.popup.border = "rounded";
      filesystem.window.popup.border = "rounded";

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
