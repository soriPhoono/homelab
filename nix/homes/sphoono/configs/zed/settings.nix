{
  lib,
  config,
  ...
}:
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
      opencode = {
        type = "custom";
        command = "opencode";
        args = [
          "acp"
        ];
      };
      pi = mkIf config.userapps.development.agents.pi-agent.enable {
        type = "custom";
        command = "omp";
        args = [
          "acp"
        ];
      };
    };
    agent = {
      inline_assistant_model = {
        provider = "opencode-go";
        model = "deepseek-v4-pro";
      };
      commit_message_model = {
        provider = "opencode-go";
        model = "big-pickle";
      };
    };
    context_servers = mkForce {};
  };
}
