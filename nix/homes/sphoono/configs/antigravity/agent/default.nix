{
  pkgs,
  config,
  ...
}: {
  apps.development.agents.antigravity = {
    enable = true;

    instructions = ''
      # Antigravity instructions:

      ## User outline:
      ${builtins.readFile ../../assets/documents/user.md}

      ## Antigravity instructions:
      ${builtins.readFile ../../assets/documents/antigravity/GEMINI.md}
    '';

    skills = {
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
        # Read/write the obsidian vault for inter-agent handoff notes
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@bitbonsai/mcpvault@latest"
          "${config.home.homeDirectory}/Shared/Vault"
        ];
      };
    };
  };
}
