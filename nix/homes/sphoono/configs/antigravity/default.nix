{
  pkgs,
  config,
  ...
}: {
  imports = [
    ./settings.nix
    ./extensions.nix
    ./keybindings.nix
    ./snippets.nix
  ];

  apps.development.editors.antigravity = {
    # Active profiles — switch via VS Code profile picker
    activeProfiles = ["devops" "fullstack" "webdev"];

    agent = {
      enable = true;

      instructions = ''
        # User

        ${builtins.readFile ../assets/documents/user.md}

        ${builtins.readFile ../assets/documents/GEMINI.md}
      '';

      skills = {
        create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;

        stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

        git-commit = pkgs.skills.github.awesome-copilot.git-commit;
      };

      mcpServers = {
        "obsidian" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@bitbonsai/mcpvault@latest"
            "${config.home.homeDirectory}/Nextcloud/Vault"
          ];
        };

        "sequential-thinking" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-sequential-thinking"
          ];
        };

        "arxiv" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "arxiv-query-mcp"
          ];
        };

        "wikipedia" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "wikipedia-mcp-server"
          ];
        };

        "filesystem" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "@modelcontextprotocol/server-filesystem"
            "${config.home.homeDirectory}/Projects"
          ];
        };

        "nixos" = {
          command = "${pkgs.uv}/bin/uvx";
          args = [
            "mcp-nixos"
          ];
        };

        "database" = {
          command = "${pkgs.nodejs}/bin/npx";
          args = [
            "-y"
            "anydb-mcp"
          ];
        };

        "github" = {
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
      };
    };
  };
}
