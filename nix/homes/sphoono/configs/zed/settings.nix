{lib, ...}:
with lib; {
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
    agent = {
      inline_assistant_model = {
        provider = "opencode";
        model = "deepseek-v4-pro";
      };
      commit_message_model = {
        provider = "opencode";
        model = "big-pickle";
      };
    };
    context_servers = mkForce {};
  };
}
