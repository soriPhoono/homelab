{
  lib,
  config,
  ...
}:
with lib; {
  config = mkMerge [
    {
      userapps.development.agents.opencode = {
        mcpServers = {
          stdio = {
            memory = {
              command = "bash";
              args = [
                "-c"
                "MEMORY_FILE_PATH=$HOME/.local/share/opencode/memory/memory.jsonl exec npx -y @modelcontextprotocol/server-memory"
              ];
            };

            fetch = {
              command = "uvx";
              args = [
                "mcp-server-fetch"
              ];
            };

            sequential-thinking = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-sequential-thinking"
              ];
            };

            nixos = {
              command = "uvx";
              args = [
                "mcp-nixos"
              ];
            };

            filesystem = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-filesystem"
                config.home.homeDirectory
              ];
            };

            git = {
              command = "npx";
              args = [
                "-y"
                "@selfagency/git-mcp"
              ];
            };

            obsidian = {
              command = "npx";
              args = [
                "-y"
                "@bitbonsai/mcpvault@latest"
                "${config.home.homeDirectory}/Nextcloud/Vault"
              ];
            };
          };
        };
      };
    }
  ];
}
