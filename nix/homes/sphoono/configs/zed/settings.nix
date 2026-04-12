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
    agent = {
      inline_assistant_model = {
        provider = "copilot";
        model = "gemini-3.1-pro-preview";
        enable_thinking = false;
      };
      default_model = {
        provider = "copilot";
        model = "gemini-3.1-pro-preview";
        enable_thinking = true;
        effort = "high";
      };
      favorite_models = [
        {
          provider = "copilot";
          model = "gemini-3.1-pro-preview";
          enable_thinking = true;
          effort = "high";
        }
        {
          provider = "copilot";
          model = "gemini-3.1-pro-preview";
          enable_thinking = true;
          effort = "high";
        }
      ];
      model_parameters = [];
    };
    agent_servers = {
      gemini.type = "registry";
      opencode.type = "registry";
    };
  };
}
