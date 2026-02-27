{
  keymaps = [
    {
      key = "<leader>tt";
      mode = "n";
      silent = true;
      action = "<cmd>ToggleTerm direction=float<CR>";
    }

    # Window navigation (Ctrl+hjkl)
    {
      key = "<C-h>";
      mode = "n";
      action = "<C-w>h";
      desc = "Move to left window";
    }
    {
      key = "<C-j>";
      mode = "n";
      action = "<C-w>j";
      desc = "Move to lower window";
    }
    {
      key = "<C-k>";
      mode = "n";
      action = "<C-w>k";
      desc = "Move to upper window";
    }
    {
      key = "<C-l>";
      mode = "n";
      action = "<C-w>l";
      desc = "Move to right window";
    }

    # Buffer navigation
    {
      key = "<Tab>";
      mode = "n";
      action = "<cmd>bnext<CR>";
      desc = "Next buffer";
    }
    {
      key = "<S-Tab>";
      mode = "n";
      action = "<cmd>bprev<CR>";
      desc = "Previous buffer";
    }

    # Clear search highlight
    {
      key = "<Esc>";
      mode = "n";
      action = "<cmd>nohlsearch<CR>";
      desc = "Clear search";
    }

    # Aerial (Document Outline)
    {
      key = "<leader>oa";
      mode = "n";
      action = "<cmd>AerialToggle!<CR>";
      desc = "Toggle document outline";
    }
  ];

  binds.whichKey = {
    enable = true;
    setupOpts.preset = "helix";
  };

  utility = {
    images.image-nvim = {
      enable = true;
      setupOpts.backend = "kitty";
    };
    direnv.enable = true;
    mkdir.enable = true;
    multicursors.enable = true;
    surround.enable = true;
    diffview-nvim.enable = true;
    undotree.enable = true;
    outline.aerial-nvim = {
      enable = true;
      setupOpts.attach_mode = "global";
    };

    # Motion plugin
    motion.flash-nvim = {
      enable = true;
      setupOpts.modes.search.enabled = true;
      mappings.jump = "s";
    };
  };

  terminal.toggleterm.enable = true;

  treesitter = {
    enable = true;
    autotagHtml = true;
  };

  telescope.enable = true;

  autopairs.nvim-autopairs.enable = true;
  comments.comment-nvim.enable = true;
}
