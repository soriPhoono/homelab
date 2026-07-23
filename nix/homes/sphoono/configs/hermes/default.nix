{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes = {
    enable = true;

    providers = {
      models.openrouter.enable = true;
      memory.variant = "honcho";
      search.exa.enable = true;
    };

    skills = {
      stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;
      vault-structure = pkgs.skills.soriphoono.skills.vault-structure;
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
    };

    profiles = {
      default = {
        providers.memory.honcho = {
          workspace = "general";
        };

        documents = {
          soul = ../assets/documents/default/soul.md;
          user = ../assets/documents/user.md;
        };

        permissions = {
          accessDirectories = [
            "${config.home.homeDirectory}/Downloads"
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/Pictures"
            "${config.home.homeDirectory}/Music"
            "${config.home.homeDirectory}/Videos"
          ];
        };

        mcpServers = {
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
          "personal/markitdown" = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "markitdown-mcp"
            ];
          };
        };
      };

      coder = {
        providers.memory.honcho = {
          workspace = "software-development";
        };

        documents = {
          soul = ../assets/documents/coder/soul.md;
          user = ../assets/documents/user.md;
        };

        permissions = {
          accessDirectories = [
            "${config.home.homeDirectory}/Projects"
          ];
        };

        skills = {
          create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;
          git-commit = pkgs.skills.github.awesome-copilot.git-commit;
        };

        mcpServers = {
          "software-dev/github" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-github"
            ];
            env = {
              GITHUB_PERSONAL_ACCESS_TOKEN = {
                secret = "api/GITHUB_TOKEN";
              };
            };
          };
          "software-dev/nixos" = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "mcp-nixos"
            ];
          };
          "software-dev/database" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "anydb-mcp"
            ];
          };
        };
      };
    };
  };
}
