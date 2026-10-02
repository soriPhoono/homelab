_: {
  programs.nvf.settings.vim = {
    # <leader>lt is a prefix for telescope type definitions and this toggle.
    lsp.mappings.toggleFormatOnSave = "<leader>lF";

    binds = {
      whichKey = {
        enable = true;
        setupOpts = {
          preset = "modern";
          notify = true;
        };
        register = {
          "<leader>?" = "Cheatsheet";
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
        };
      };
      cheatsheet.enable = true;
    };
  };
}
