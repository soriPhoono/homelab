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
      # opencode = mkIf config.userapps.development.agents.opencode.enable {
      #   type = "registry";
      # };
      # pi-acp = mkIf config.userapps.development.agents.pi.enable {
      #   type = "registry";
      # };
    };
    agent = {
      default_model = {
        provider = "opencode";
        model = "go/deepseek-v4-flash";
        enable_thinking = true;
        effort = "high";
      };
      inline_assistant_model = {
        provider = "opencode";
        model = "go/deepseek-v4-pro";
      };
      commit_message_model = {
        provider = "opencode";
        model = "free/big-pickle";
      };
    };
    context_servers = mkForce {};
  };
}
