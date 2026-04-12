{
  pkgs,
  config,
  ...
}: {
  programs.opencode.settings.mcp = {
    # DevOps / System
    filesystem = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}"];
    };

    # Development - Knowledge
    memory = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-memory"];
    };

    sequential-thinking = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-sequential-thinking"];
    };

    # Knowledge / Notes
    obsidian = {
      type = "local";
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@bitbonsai/mcpvault@latest" "${config.home.homeDirectory}/Nextcloud/Notes"];
    };

    # Development - Web2
    fetch = {
      type = "local";
      command = ["${pkgs.uv}/bin/uvx" "mcp-server-fetch"];
    };

    # Development - Git
    git = {
      type = "local";
      command = ["${pkgs.uv}/bin/uvx" "mcp-server-git"];
    };

    github = {
      type = "remote";
      url = "https://api.githubcopilot.com/mcp";
      headers = {
        Authorization = "Bearer {env:GITHUB_API_KEY}";
      };
    };

    exa = {
      type = "remote";
      url = "https://mcp.exa.ai";
      headers = {
        x-api-key = "{env:EXA_API_KEY}";
      };
    };

    # Development - Code Intelligence
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      };
    };
  };
}
