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
    agent = {
      default_model = {
        provider = "openrouter";
        model = "google/gemini-3-flash-preview";
      };
      inline_assistant_model = {
        provider = "openrouter";
        model = "google/gemini-3.1-flash-lite";
      };
      commit_message_model = {
        provider = "openrouter";
        model = "free";
      };
      thread_summary_model = {
        provider = "openrouter";
        model = "free";
      };
    };
  };
}
