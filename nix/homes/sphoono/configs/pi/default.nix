{pkgs, ...}: {
  imports = [
    ./mcp.nix
  ];

  userapps.development.agentics = {
    context = ./AGENTS.md;

    skills = {
      create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;

      stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

      git-commit = pkgs.skills.github.awesome-copilot.git-commit;
    };
  };

  userapps.development.agents.pi = {
    userSettings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
    };

    secrets = [
      "api/GITHUB_API_KEY"
      "api/EXA_API_KEY"
      "api/CONTEXT7_API_KEY"
    ];

    packages = [
      "git:git@github.com:soriPhoono/pi-package"

      "npm:pi-subagents"
    ];
  };
}
