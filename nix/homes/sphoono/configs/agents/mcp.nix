{
  pkgs,
  config,
  ...
}: {
  userapps.development.agentics.mcp = {
    filesystem = {
      transport = "stdio";
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-filesystem"
        config.home.homeDirectory
      ];
    };

    memory = {
      transport = "stdio";
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-memory"
      ];
    };

    sequential-thinking = {
      transport = "stdio";
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@modelcontextprotocol/server-sequential-thinking"
      ];
    };

    obsidian = {
      transport = "stdio";
      command = "${pkgs.nodejs}/bin/npx";
      args = [
        "-y"
        "@bitbonsai/mcpvault@latest"
        "${config.home.homeDirectory}/Nextcloud/Notes"
      ];
    };

    fetch = {
      transport = "stdio";
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "mcp-server-fetch"
      ];
    };

    git = {
      transport = "stdio";
      command = "${pkgs.uv}/bin/uvx";
      args = [
        "mcp-server-git"
      ];
    };

    github = {
      url = "https://api.githubcopilot.com/mcp";
      headers.Authorization = {
        secret = "api/GITHUB_API_KEY";
        prefix = "Bearer ";
      };
    };

    exa = {
      url = "https://mcp.exa.ai";
      headers."x-api-key" = {
        secret = "api/EXA_API_KEY";
      };
    };

    context7 = {
      url = "https://mcp.context7.com/mcp";
      headers.CONTEXT7_API_KEY = {
        secret = "api/CONTEXT7_API_KEY";
      };
    };
  };
}
