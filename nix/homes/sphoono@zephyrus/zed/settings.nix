{
  userapps.development.editors.zed.userSettings = {
    soft_wrap = "bounded";
    agent = {
      inline_assistant_model = {
        provider = "google";
        model = "gemini-3-flash-preview";
        enable_thinking = false;
      };
      default_model = {
        provider = "google";
        model = "gemini-3.1-pro-preview";
        enable_thinking = true;
      };
      favorite_models = [
        {
          provider = "google";
          model = "gemini-3-flash-preview";
          enable_thinking = true;
        }
        {
          model = "gemini-3.1-pro-preview";
          enable_thinking = true;
          provider = "google";
        }
      ];
      model_parameters = [];
    };
    terminal = {
      toolbar = {
        breadcrumbs = true;
      };
      shell = "system";
    };
    agent_servers = {
      opencode = {
        type = "registry";
      };
      gemini = {
        type = "registry";
      };
    };
    base_keymap = "Atom";
  };
}
