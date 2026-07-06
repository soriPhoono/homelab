{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  config = {
    userapps.development.agents.hermes = {
      # ── Common MCP servers (applied to default agent + all profiles) ───
      mcpServers = {
        "personal/obsidian" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@bitbonsai/mcpvault@latest"
            "${config.home.homeDirectory}/Nextcloud/Vault"
          ];
        };

        "personal/sequential-thinking" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };

        "personal/arxiv" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "arxiv-query-mcp"
          ];
        };

        "personal/wikipedia" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "wikipedia-mcp-server"
          ];
        };

        "personal/brave-search" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@brave/brave-search-mcp-server"
          ];
          env = {
            BRAVE_API_KEY = {
              secret = "api/BRAVE_API_KEY";
            };
          };
        };
      };
    };
  };
}
