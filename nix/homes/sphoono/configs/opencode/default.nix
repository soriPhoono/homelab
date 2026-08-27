{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.opencode = {
    enable = true;

    documents."AGENTS.md" = ''
      # OpenCode instructions:

      ## User outline:
      ${builtins.readFile ../assets/documents/user.md}

      ## OpenCode instructions:
      ${builtins.readFile ../assets/documents/opencode/AGENTS.md}
    '';

    # Honcho persistent memory for the software-development pipeline.
    secrets = [
      "api/HONCHO_API_KEY"
    ];

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
