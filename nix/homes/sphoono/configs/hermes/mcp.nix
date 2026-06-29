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

        "personal/nixos" = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "mcp-nixos"
          ];
        };

        "personal/sequential-thinking" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };
      };
    };
  };
}
