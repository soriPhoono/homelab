_: {
  vim.projects.project-nvim = {
    enable = true;

    setupOpts = {
      # Change to the detected project root automatically.
      manual_mode = false;
      detection_methods = ["lsp" "pattern"];
      silent_chdir = true;
      scope_chdir = "tab";
    };
  };
}
