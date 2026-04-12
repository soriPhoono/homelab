{
  pkgs,
  config,
  ...
}: {
  programs.gemini-cli.settings.mcpServers = {
    filesystem = {
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-filesystem" "${config.home.homeDirectory}"];
    };

    memory = {
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-memory"];
    };

    sequential-thinking = {
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@modelcontextprotocol/server-sequential-thinking"];
    };

    obsidian = {
      command = "${pkgs.nodejs}/bin/npx";
      args = ["-y" "@bitbonsai/mcpvault@latest" "${config.home.homeDirectory}/Nextcloud/Notes"];
    };

    fetch = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["mcp-server-fetch"];
    };

    git = {
      command = "${pkgs.uv}/bin/uvx";
      args = ["mcp-server-git"];
    };

    github = {
      url = "https://api.githubcopilot.com/mcp";
      headers = {
        Authorization = "Bearer $GITHUB_API_KEY";
      };
    };

    exa = {
      url = "https://mcp.exa.ai";
      headers = {
        x-api-key = "$EXA_API_KEY";
      };
    };

    context7 = {
      url = "https://mcp.context7.com/mcp";
      headers = {
        CONTEXT7_API_KEY = "$CONTEXT7_API_KEY";
      };
    };
  };
}
