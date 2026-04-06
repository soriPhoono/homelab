{
  pkgs,
  config,
  ...
}: {
  sops.secrets = {
    "api/GITHUB_API_KEY" = {};
  };

  userapps.development.editors.zed.userSettings = {
    terminal = {
      toolbar.breadcrumbs = true;
      shell = "system";
    };
    edit_predictions = {
      provider = "codestral";
      mode = "eager";
    };
    soft_wrap = "bounded";
    base_keymap = "Atom";
    load_direnv = "shell_hook";
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
    context_servers = {
      GitHub = {
        command = let
          github-mcp-script = pkgs.writeShellApplication {
            name = "github-mcp";
            text = ''
              GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.sops.secrets."api/GITHUB_API_KEY".path})
              export GITHUB_PERSONAL_ACCESS_TOKEN
              exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github "$@"
            '';
          };
        in "${github-mcp-script}/bin/github-mcp";
        args = [];
        env = {};
      };
    };
    agent_servers.opencode.type = "registry";
  };
}
