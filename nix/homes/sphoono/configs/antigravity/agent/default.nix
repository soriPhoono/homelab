{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.antigravity = {
    enable = true;

    instructions = ''
      # User

      ${builtins.readFile ../../assets/documents/user.md}

      ${builtins.readFile ../../assets/documents/GEMINI.md}
    '';

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

      "personal/filesystem" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "${config.home.homeDirectory}/Documents"
          "${config.home.homeDirectory}/Pictures"
          "${config.home.homeDirectory}/Music"
          "${config.home.homeDirectory}/Videos"
          "${config.home.homeDirectory}/Projects"
        ];
      };

      "personal/honcho" = {
        url = "https://mcp.honcho.dev";
        headers = {
          Authorization = {
            prefix = "Bearer ";
            secret = "api/HONCHO_API_KEY";
          };
          "X-Honcho-User-Name" = "soriphoono";
          "X-Honcho-Assistant-Name" = "Antigravity";
          "X-Honcho-Workspace-ID" = "software-development";
        };
      };
    };
  };
}
