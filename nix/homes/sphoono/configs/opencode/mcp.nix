{
  pkgs,
  config,
  ...
}: {
  userapps.development.agents.opencode.settings.mcp = {
    # DevOps / System
    filesystem = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}"];
    };

    # Development - Git
    git = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-git" "--repository" "."];
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

    # Development - Knowledge
    memory = {
      type = "local";
      command = ["${pkgs.uv}/bin/uvx" "mcp-server-memory"];
    };

    # Development - Web2
    fetch = {
      type = "local";
      command = ["${pkgs.uv}/bin/uvx" "mcp-server-fetch"];
    };

    exa = {
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

    # Development - Code Intelligence
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

    sequential-thinking = {
      type = "local";
      command = ["${pkgs.uv}/bin/uvx" "mcp-sequential-thinking"];
    };

    # Knowledge / Notes
    obsidian = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@bitbonsai/mcpvault@latest" "${config.home.homeDirectory}/Nextcloud/Notes"];
    };
  };
}
