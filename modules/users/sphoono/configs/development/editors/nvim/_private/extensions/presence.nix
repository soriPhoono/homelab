_: {
  # Discord rich presence. The defaults publish the project and file names, so
  # the activity text is generic.
  programs.nvf.settings.vim.presence.cord-nvim = {
    enable = true;
    setupOpts.text = {
      workspace = "In a project";
      viewing = "Viewing a file";
      editing = "Editing a file";
    };
  };
}
