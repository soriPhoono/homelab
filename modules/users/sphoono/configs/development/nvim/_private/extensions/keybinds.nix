_: {
  programs.nvf.settings.vim = {
    # <leader>lt is a prefix for telescope type definitions and this toggle.
    lsp.mappings.toggleFormatOnSave = "<leader>lF";

    keymaps = [
      {
        mode = "n";
        key = "<leader>fc";
        action = "<cmd>Cheatsheet<CR>";
        desc = "Cheatsheet";
      }
      # cheatsheet.nvim maps <leader>? on load unless something already does,
      # and that fires instead of the native ? backward search.
      {
        mode = "n";
        key = "<leader>?";
        action = "<Nop>";
        desc = "which_key_ignore";
      }
    ];

    binds = {
      whichKey = {
        enable = true;
        setupOpts = {
          preset = "modern";
          notify = true;
        };
        register = {
          "<leader>b" = "+Buffers";
          "<leader>bm" = "+Move";
          "<leader>bs" = "+Sort";
          "<leader>dg" = "+Step";
          "<leader>dv" = "+Stack";
          "<leader>e" = "Neo-tree";
          "<leader>f" = "+Find";
          "<leader>fl" = "+LSP";
          "<leader>g" = "+Git";
          "<leader>h" = "+Hunks";
          "<leader>l" = "+LSP";
          "<leader>lg" = "+Goto";
          "<leader>lw" = "+Workspace folders";
          "<leader>m" = "+Multicursor";
          "<leader>mc" = "+Create";
        };
      };
      cheatsheet.enable = true;
    };
  };
}
