{config, ...}: {
  sops.templates."editor/antigravity-mcp.json" = {
    content = ''
      {
          "mcpServers": {
              "filesystem": {
                  "command": "npx",
                  "args": [
                      "-y",
                      "@modelcontextprotocol/server-filesystem",
                      "${config.home.homeDirectory}"
                  ]
              },
              "memory": {
                  "command": "npx",
                  "args": [
                      "-y",
                      "@modelcontextprotocol/server-memory"
                  ]
              },
              "sequential-thinking": {
                  "command": "npx",
                  "args": [
                      "-y",
                      "@modelcontextprotocol/server-sequential-thinking"
                  ]
              },
              "obsidian": {
                  "command": "npx",
                  "args": [
                      "-y",
                      "@bitbonsai/mcpvault@latest",
                      "${config.home.homeDirectory}/Nextcloud/Notes"
                  ]
              },
              "fetch": {
                  "command": "uvx",
                  "args": [
                      "mcp-server-fetch"
                  ]
              },
              "git": {
                  "command": "uvx",
                  "args": [
                      "mcp-server-git"
                  ]
              },
              "github": {
                  "serverUrl": "https://api.githubcopilot.com/mcp",
                  "headers": {
                      "Authorization": "Bearer ${config.sops.placeholder."api/GITHUB_API_KEY"}"
                  }
              },
              "exa": {
                  "serverUrl": "https://mcp.exa.ai",
                  "headers": {
                      "x-api-key": "${config.sops.placeholder."api/EXA_API_KEY"}"
                  }
              },
              "context7": {
                  "serverUrl": "https://mcp.context7.com/mcp",
                  "headers": {
                      "CONTEXT7_API_KEY": "${config.sops.placeholder."api/CONTEXT7_API_KEY"}"
                  }
              }
          }
      }
    '';
    path = "${config.home.homeDirectory}/.gemini/antigravity/mcp_config.json";
  };
}
