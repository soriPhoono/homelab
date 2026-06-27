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
          # github = {
          #   url = "https://api.githubcopilot.com/mcp";
          #   headers = {
          #     Authorization = {
          #       secret = "api/GITHUB_API_KEY";
          #       prefix = "Bearer ";
          #     };
          #   };
          # };

          exa = {
            url = "https://mcp.exa.ai";
            headers = {
              x-api-key = {
                secret = "api/EXA_API_KEY";
              };
            };
          };

          context7 = {
            url = "https://mcp.context7.com/mcp";
            headers = {
              CONTEXT7_API_KEY = {
                secret = "api/CONTEXT7_API_KEY";
              };
            };
          };

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
    }
  ];
}
