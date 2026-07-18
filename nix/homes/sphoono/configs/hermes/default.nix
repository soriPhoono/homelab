{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes = {
    enableCli = true;
    enableDesktop = true;

    providers = {
      models = {
        opencode = {
          go = {
            enable = true;
            default = true;
            model = "deepseek-v4-flash";
          };
        };
      };

      memory.variant = "honcho";
      search.exa.enable = true;
    };

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
    };

    profiles = {
      default = {
        documents = {
          soul = ../assets/documents/default/soul.md;
          user = ../assets/documents/user.md;
        };

        mcpServers = {
          "office/pptx" = {
            command = "${pkgs.office-mcp}/bin/office-mcp-pptx";
            args = [];
          };
          "office/docx" = {
            command = "${pkgs.office-mcp}/bin/office-mcp-docx";
            args = [];
          };
          "office/xlsx" = {
            command = "${pkgs.office-mcp}/bin/office-mcp-xlsx";
            args = [];
          };
          "office/pdf" = {
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "pdf-edit-mcp"
            ];
          };
          "personal/filesystem" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-filesystem"
              "${config.home.homeDirectory}/Documents"
            ];
          };
        };
      };
      coder = {
        type = "background";
        documents = {
          soul = ../assets/documents/coder/soul.md;
          user = ../assets/documents/user.md;
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
          "personal/filesystem" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-filesystem"
              "${config.home.homeDirectory}/Projects"
            ];
          };
        };
      };
    };
  };
}
