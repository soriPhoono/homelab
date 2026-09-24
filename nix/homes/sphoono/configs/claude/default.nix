{pkgs, ...}: {
  apps.development.agents.claude = {
    enable = true;

    userSettings = {
      theme = "dark";

      model = "claude-sonnet-5";
      effortLevel = "medium";

      permissions.defaultMode = "auto";

      # mem0: agent-maintained memory layer, installed via `/plugin marketplace add`
      # and `/plugin install` rather than the module's plugins/marketplaces options,
      # because it ships from mem0ai/mem0's own marketplace manifest.
      extraKnownMarketplaces."mem0-plugins" = {
        source = {
          source = "github";
          repo = "mem0ai/mem0";
        };
      };
      enabledPlugins."mem0@mem0-plugins" = true;
    };

    documents."AGENTS.md" = ''
      ## Claude instructions:

      ### User outline:
      ${builtins.readFile ../assets/documents/user.md}

      ### Claude Code instructions:
      ${builtins.readFile ../assets/documents/claude/AGENTS.md}
    '';

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
    };

    mcpServers = {
      "personal/sequential-thinking" = {
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
      };
      "personal/notion" = {
        url = "https://mcp.notion.com/mcp";
      };
    };
  };
}
