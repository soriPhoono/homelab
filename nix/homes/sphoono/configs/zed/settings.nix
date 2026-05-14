{
  programs.zed-editor.userSettings = {
    terminal = {
      toolbar.breadcrumbs = true;
      shell = "system";
    };
    edit_predictions = {
      provider = "copilot";
      mode = "eager";
    };
    soft_wrap = "bounded";
    base_keymap = "Atom";
    load_direnv = "shell_hook";
    agent_servers = {
      gemini.type = "registry";
      opencode.type = "registry";
    };
  };
}
