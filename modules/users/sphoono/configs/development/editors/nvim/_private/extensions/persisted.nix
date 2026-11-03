_: {
  programs.nvf.settings.vim = {
    session.persisted.enable = true;

    # persisted maps <leader>qs to load and <leader>ql to pick a session.
    binds.whichKey.register."<leader>q" = "+Session";
  };
}
