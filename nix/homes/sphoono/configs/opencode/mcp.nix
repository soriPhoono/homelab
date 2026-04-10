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
      command = ["${pkgs.nodejs}/bin/npx" "-y" "@modelcontextprotocol/server-git" "--repository" "$PWD"];
    };

    github = {
      type = "remote";
      url = "https://api.githubcopilot.com/mcp/";
      enabled = true;
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
      type = "remote";
      url = "https://mcp.exa.ai/mcp/";
      enabled = true;
    };

    # Development - Code Intelligence
    context7 = {
      type = "remote";
      url = "https://mcp.context7.com/mcp/oauth";
      enabled = true;
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
