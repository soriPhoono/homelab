{pkgs, ...}: {
  userapps.development.editors.zed.userSettings = {
    soft_wrap = "bounded";
    base_keymap = "Atom";
    load_direnv = "shell_hook";
    terminal = {
      toolbar = {
        breadcrumbs = true;
      };
      shell = "system";
    };
    agent_servers = {
      opencode = {
        type = "custom";
        command = "${pkgs.opencode}/bin/opencode";
        args = ["acp"];
      };
    };
    edit_predictions = {
      provider = "codestral";
      mode = "eager";
    };
    agent = {
      inline_assistant_model = {
        provider = "openrouter";
        model = "google/gemini-3.1-pro-preview";
        enable_thinking = false;
      };
      default_model = {
        provider = "openrouter";
        model = "google/gemini-3.1-pro-preview";
        enable_thinking = true;
        effort = "high";
      };
      favorite_models = [
        {
          provider = "openrouter";
          model = "google/gemini-3-flash-preview";
          enable_thinking = true;
          effort = "high";
        }
        {
          provider = "openrouter";
          model = "google/gemini-3.1-pro-preview";
          enable_thinking = true;
          effort = "high";
        }
      ];
      model_parameters = [];
    };
  };
}
