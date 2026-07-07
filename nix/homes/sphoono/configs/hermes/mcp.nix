{
  lib,
  pkgs,
  config,
  ...
}:
with lib; {
  config = {
    apps.development.agents.hermes = {
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
      };
    };
  };
}
