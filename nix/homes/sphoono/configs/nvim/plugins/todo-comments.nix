_: {
  vim.notes.todo-comments = {
    enable = true;

    setupOpts = {
      highlight = {
        pattern = ''.*<(KEYWORDS)(\([^\)]*\))?:'';
      };
    };
  };
}
