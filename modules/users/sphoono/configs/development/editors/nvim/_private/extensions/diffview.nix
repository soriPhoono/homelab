_: {
  programs.nvf.settings.vim = {
    utility.diffview-nvim.enable = true;

    # nvf maps nothing for diffview. <leader>gd/gh/gq are free in the Git group.
    keymaps = [
      {
        mode = "n";
        key = "<leader>gd";
        action = "<cmd>DiffviewOpen<CR>";
        desc = "Diff view";
      }
      {
        mode = "n";
        key = "<leader>gh";
        action = "<cmd>DiffviewFileHistory %<CR>";
        desc = "File history";
      }
      {
        mode = "n";
        key = "<leader>gq";
        action = "<cmd>DiffviewClose<CR>";
        desc = "Close diff view";
      }
    ];
  };
}
