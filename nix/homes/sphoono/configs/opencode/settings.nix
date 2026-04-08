{
  pkgs,
  config,
  ...
}: {
  # sops.secrets."api/EXA_API_KEY" = {};

  userapps.development.agents.opencode.settings = {
    model = "openrouter/google/gemini-3-flash-preview";

    # NOTE: These are the models to use at the top of the month till the usage runs out on my google cloud credit.
    # model = "openrouter/google/gemini-3-flash-preview";
    # small_model = "openrouter/free";

    provider = {
      openrouter = {
        options = {
          apiKey = "{env:OPENROUTER_API_KEY}";
        };
      };
    };

    mcp = {
      obsidian = {
        type = "local";
        command = ["npx" "-y" "@bitbonsai/mcpvault@latest" "${config.home.homeDirectory}/Nextcloud/Notes"];
      };
      exa = {
        # type = "remote";
        # url = "https://mcp.exa.ai/mcp";
        # enabled = true;
        type = "local";
        command = let
          exa-mcp-script = pkgs.writeShellApplication {
            name = "exa-mcp";
            text = ''
              EXA_API_KEY=$(cat ${config.sops.secrets."api/EXA_API_KEY".path})
              export EXA_API_KEY
              exec ${pkgs.nodejs}/bin/npx -y mcp-remote https://mcp.exa.ai/mcp?exaApiKey="$EXA_API_KEY"
            '';
          };
        in ["${exa-mcp-script}/bin/exa-mcp"];
      };
      github = {
        type = "local";
        command = let
          github-mcp-script = pkgs.writeShellApplication {
            name = "github-mcp";
            text = ''
              GITHUB_PERSONAL_ACCESS_TOKEN=$(cat ${config.sops.secrets."api/GITHUB_API_KEY".path})
              export GITHUB_PERSONAL_ACCESS_TOKEN
              exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github "$@"
            '';
          };
        in ["${github-mcp-script}/bin/github-mcp"];
      };
      context7 = {
        type = "local";
        command = let
          context7-mcp-script = pkgs.writeShellApplication {
            name = "context7-mcp";
            text = ''
              CONTEXT7_API_KEY=$(cat ${config.sops.secrets."api/CONTEXT7_API_KEY".path})
              export CONTEXT7_API_KEY
              exec ${pkgs.nodejs}/bin/npx -y @upstash/context7-mcp --api-key "$CONTEXT7_API_KEY" "$@"
            '';
          };
        in ["${context7-mcp-script}/bin/context7-mcp"];
      };
    };
  };
}
