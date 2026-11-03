_: {
  programs.nvf.settings.vim = {
    notes.todo-comments = {
      enable = true;
      # <leader>td is a prefix next to the Test group; neotest uses uppercase D.
      mappings = {
        quickFix = "<leader>tdq";
        telescope = "<leader>tds";
        trouble = "<leader>tdt";
      };
    };

    binds.whichKey.register."<leader>td" = "+Todo comments";
  };
}
