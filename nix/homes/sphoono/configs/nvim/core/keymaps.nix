_: {
  vim = {
    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    keymaps = [
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        desc = "Focus left window";
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        desc = "Focus lower window";
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        desc = "Focus upper window";
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        desc = "Focus right window";
      }
      {
        mode = "n";
        key = "<leader>bn";
        action = "<cmd>BufferLineCycleNext<CR>";
        desc = "Next buffer";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<cmd>BufferLineCyclePrev<CR>";
        desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<leader>wv";
        action = "<cmd>vsplit<CR>";
        desc = "Split window vertically";
      }
      {
        mode = "n";
        key = "<leader>ws";
        action = "<cmd>split<CR>";
        desc = "Split window horizontally";
      }
    ];
  };
}
