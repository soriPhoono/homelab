{
  pkgs,
  config,
  ...
}: {
  userapps.development.agents.agentics = {
    mcpServers = {
      stdio = {
        # Docker-based MCP servers (no host filesystem dependency)
        memory = {
          command = "${pkgs.docker}/bin/docker";
          args = [
            "run"
            "-i"
            "--rm"
            "-e"
            "MEMORY_FILE_PATH=/data/memory.jsonl"
            "-v"
            "${config.home.homeDirectory}/.local/share/pi/memory:/data"
            "mcp/memory"
          ];
        };

        fetch = {
          command = "${pkgs.docker}/bin/docker";
          args = [
            "run"
            "-i"
            "--rm"
            "mcp/fetch"
          ];
        };

        sequential-thinking = {
          command = "${pkgs.docker}/bin/docker";
          args = [
            "run"
            "-i"
            "--rm"
            "mcp/sequentialthinking"
          ];
        };

        # npx-based MCP servers (need host filesystem access)
        filesystem = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            config.home.homeDirectory
          ];
        };

        git = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@selfagency/git-mcp"
          ];
        };

        # Already npx-based
        obsidian = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@bitbonsai/mcpvault@latest"
            "${config.home.homeDirectory}/Nextcloud/Notes"
          ];
        };

        # Already uvx-based
        serena = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "--from"
            "serena-agent"
            "serena"
            "start-mcp-server"
          ];
        };
      };

      http = {
        github = {
          url = "https://api.githubcopilot.com/mcp";
          headers = {
            Authorization = {
              secret = "api/GITHUB_API_KEY";
              prefix = "Bearer ";
            };
          };
        };

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
      };
    };
  };
}
