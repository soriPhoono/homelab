{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.opencode = {
    enable = true;

    extraPackages = with pkgs; [
      # 3rd party service access
      composio
    ];

    ollama = {
      enable = true;
      baseUrl = "https://desktop-ares-inference.xerus-augmented.ts.net/v1";
      models = {
        "qwen3.8" = {
          name = "qwen-3.8";
        };
      };
    };

    # Honcho persistent memory for the software-development pipeline.
    secrets = [
      "api/HONCHO_API_KEY"
    ];

    documents."AGENTS.md" = ''
      # OpenCode instructions:

      ## User outline:
      ${builtins.readFile ../assets/documents/user.md}

      ## OpenCode instructions:
      ${builtins.readFile ../assets/documents/opencode/AGENTS.md}
    '';

    agents = {
      systems-engineer = ../assets/documents/opencode/systems-engineer.md;
      research-partner = ../assets/documents/opencode/research-agent.md;
    };

    skills = {
      stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

      grilling = pkgs.skills.mattpocock.skills.grilling;
      grill-me = pkgs.skills.mattpocock.skills.grill-me;
      grill-with-docs = pkgs.skills.mattpocock.skills.grill-with-docs;
      domain-modeling = pkgs.skills.mattpocock.skills.domain-modeling;
      wayfinder = pkgs.skills.mattpocock.skills.wayfinder;
      # to-issues = pkgs.skills.mattpocock.skills.to-issues;

      # Create agentic integrations
      create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;
      create-readme = pkgs.skills.github.awesome-copilot.create-readme;

      # Work with git repos
      git-commit = pkgs.skills.github.awesome-copilot.git-commit;

      # General 3rd party services
      composio = pkgs.skills.composio-community.skills.composio;

      # Video pipeline inter-agent manifest contract
      video-pipeline-manifest = ../assets/skills/video-pipeline-manifest;
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
        # Read/write the shared Obsidian vault for project context and handoff.
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@bitbonsai/mcpvault@latest"
          "${config.home.homeDirectory}/Shared/Vault"
        ];
      };
      "personal/outline" = {
        url = "https://desktop-ares-wiki.xerus-augmented.ts.net/mcp";
      };
      "search/brave" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@brave/brave-search-mcp-server"
        ];
        env = {
          BRAVE_API_KEY = {
            secret = "api/BRAVE_API_KEY";
          };
        };
      };
      "software-development/n8n" = {
        url = "https://desktop-ares-agents.xerus-augmented.ts.net/mcp-server/http";
        headers = {
          Authorization = {
            prefix = "Bearer ";
            secret = "api/N8N_API_KEY";
          };
        };
      };
    };

    userSettings = {
      # OpenCode resolves and installs this plugin from its package registry.
      plugin = [
        "@honcho-ai/opencode-honcho"
      ];
    };
  };

  sops = {
    secrets."api/HONCHO_API_KEY" = {};

    # Honcho shares this configuration between its supported agent hosts.
    templates."honcho/config.json" = {
      path = "${config.home.homeDirectory}/.honcho/config.json";
      content = ''
        {
          "apiKey": "${config.sops.placeholder."api/HONCHO_API_KEY"}",
          "peerName": "${config.home.username}",
          "baseUrl": "https://api.honcho.dev",
          "hosts": {
            "opencode": {
              "workspace": "software-development",
              "aiPeer": "opencode",
              "recallMode": "hybrid",
              "observationMode": "directional",
              "sessionStrategy": "per-directory"
            }
          }
        }
      '';
    };
  };
}
