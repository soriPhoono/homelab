_: {
  vim.binds = {
    whichKey = {
      enable = true;

      setupOpts = {
        preset = "modern";
        notify = true;
      };

      register = {
        "?" = "Cheatsheet";
        e = "Neo-tree";
        t = "Terminal";
      };
    };

    cheatsheet = {
      enable = true;
    };
  };
}
