_: {
  programs.nvf.settings.vim = {
    utility.undotree.enable = true;

    keymaps = [
      {
        mode = "n";
        key = "<leader>u";
        action = "<cmd>UndotreeToggle<CR>";
        desc = "Undo tree";
      }
    ];
  };
}
