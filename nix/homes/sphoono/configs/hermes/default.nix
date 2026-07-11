{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes = {
    enableCli = true;
    enableDesktop = true;

    providers = {
      opencode = {
        go = {
          enable = true;
          default = true;
          model = "deepseek-v4-flash";
        };
      };
    };

    secrets = [
      "api/EXA_API_KEY"
    ];

    skills = {
      create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;

      stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

      git-commit = pkgs.skills.github.awesome-copilot.git-commit;
    };

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

      "personal/filesystem" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}"
        ];
      };
    };

    profiles = {
      default = {
        documents = {
          soul = ./documents/default/soul.md;
        };
      };
      coder = {
        documents = {
          soul = ./documents/coder/soul.md;
        };
      };
    };
  };
}
