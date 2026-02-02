{
  programs.nvf.settings.vim = {
    keymaps = [
      {
        key = "<leader>tt";
        mode = "n";
        silent = true;
        action = "<cmd>ToggleTerm direction=float<CR>";
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
    };

    terminal.toggleterm.enable = true;

    treesitter = {
      enable = true;
      autotagHtml = true;
    };

    telescope.enable = true;

    autopairs.nvim-autopairs.enable = true;
    comments.comment-nvim.enable = true;
  };
}
