{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.hermes = {
    enable = true;

    stylixTheme.enable = true;

    providers = {
      memory.variant = "honcho";
      models = {
        ollama = {
          enable = true;
          enableCloud = true;
          model = "glm-5.2:cloud";
          default = true;
        };
        openrouter.enable = true;
      };
      search.exa.enable = true;
    };

    extraPackages = with pkgs; [
      composio
    ];

    skills = {
      stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

      grilling = pkgs.skills.mattpocock.skills.grilling;
      grill-me = pkgs.skills.mattpocock.skills.grill-me;
      grill-with-docs = pkgs.skills.mattpocock.skills.grill-with-docs;
      wayfinder = pkgs.skills.mattpocock.skills.wayfinder;
      # to-issues = pkgs.skills.mattpocock.skills.to-issues;

      # General 3rd party services
      composio = pkgs.skills.composio-community.skills.composio;

      # Video pipeline inter-agent manifest contract
      video-pipeline-manifest = ../assets/skills/video-pipeline-manifest;
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
            "${config.home.homeDirectory}/Shared"
            "${config.home.homeDirectory}/Downloads"
            "${config.home.homeDirectory}/Documents"
            "${config.home.homeDirectory}/Pictures"
            "${config.home.homeDirectory}/Music"
            "${config.home.homeDirectory}/Videos"
            "${config.home.homeDirectory}/GoogleDrive"
          ];
        };

        skills = {
          # On-demand domain skills (loaded when task matches)
          content-distribution = ../assets/skills/content-distribution;
          research-assist = ../assets/skills/research-assist;
          document-workflow = ../assets/skills/document-workflow;
        };

        mcpServers = {
          "personal/sequential-thinking" = {
            # Complex thinking and reasoning using the sequential-thinking MCP server
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
            ];
          };
          "personal/obsidian" = {
            # Read/write the obsidian vault
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@bitbonsai/mcpvault@latest"
              "${config.home.homeDirectory}/Shared/Vault"
            ];
          };
          "personal/arxiv" = {
            # Query arXiv using the arXiv MCP server for scientific papers
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "arxiv-query-mcp"
            ];
          };
          "personal/wikipedia" = {
            # Query Wikipedia using the Wikipedia MCP server for general knowledge
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "wikipedia-mcp-server"
            ];
          };
          "personal/markitdown" = {
            # Convert to markdown using markitdown
            command = "${pkgs.uv}/bin/uvx";
            args = [
              "markitdown-mcp"
            ];
          };
          "personal/pandoc" = {
            # Convert from markdown to other formats using pandoc
            "command" = "uvx";
            "args" = ["mcp-pandoc"];
          };
        };
      };

      coder = {
        extraPackages = with pkgs; [
          gh
        ];

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
          # Create agentic integrations
          create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;
          create-readme = pkgs.skills.github.awesome-copilot.create-readme;

          # Work with git repos
          git-commit = pkgs.skills.github.awesome-copilot.git-commit;

          # Work with 3rd party services
          # Github: built-in hermes github skills (github-auth, github-issues,
          # github-pr-workflow, github-code-review, github-repo-management, etc.)
          # already cover gh CLI usage — no nix-skills package needed.
        };

        mcpServers = {
          "personal/sequential-thinking" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@modelcontextprotocol/server-sequential-thinking"
            ];
          };
          "personal/obsidian" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@bitbonsai/mcpvault@latest"
              "${config.home.homeDirectory}/Shared/Vault"
            ];
          };
          "software-development/n8n" = {
            command = "${pkgs.nodejs}/bin/npx";
            args = [
              "-y"
              "@leonardsellem/n8n-mcp-server"
            ];
            env = {
              N8N_API_URL = "https://desktop-ares-agents.xerus-augmented.ts.net/api/v1";
              N8N_API_KEY = {
                secret = "api/N8N_API_KEY";
              };
            };
          };
        };
      };
    };
  };
}
