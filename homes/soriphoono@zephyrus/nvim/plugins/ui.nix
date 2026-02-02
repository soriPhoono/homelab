{
  programs.nvf.settings.vim = {
    keymaps = [
      {
        key = "\\";
        mode = "n";
        silent = true;
        action = "<CMD>Neotree toggle<CR>";
      }
    ];

    ui = {
      borders.enable = true;
      breadcrumbs.enable = true;

      noice = {
        enable = true;

        setupOpts = {
          lsp.signature.enabled = true;
          presets.inc_rename = true;
        };
      };

      smartcolumn.enable = true;

      colorizer.enable = true;
    };

    filetree = {
      neo-tree = {
        enable = true;
        setupOpts = {
          enable_cursor_hijack = true;
          auto_clean_after_session_restore = true;
          git_status_async = true;
          hide_root_node = true;
        };
      };
    };

    dashboard.dashboard-nvim.enable = true;
    statusline.lualine.enable = true;

    visuals.rainbow-delimiters.enable = true;
  };
}
