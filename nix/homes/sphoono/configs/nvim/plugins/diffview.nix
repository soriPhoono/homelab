_: {
  vim.utility.diffview-nvim = {
    enable = true;

    setupOpts = {
      enhanced_diff_hl = true;
    };
  };

  vim.keymaps = [
    {
      mode = "n";
      key = "<leader>gvo";
      action = "<cmd>DiffviewOpen<CR>";
      desc = "Open diff view";
    }
    {
      mode = "n";
      key = "<leader>gvc";
      action = "<cmd>DiffviewClose<CR>";
      desc = "Close diff view";
    }
    {
      mode = "n";
      key = "<leader>gvt";
      action = "<cmd>DiffviewFileHistory<CR>";
      desc = "Diff file history";
    }
  ];
}
