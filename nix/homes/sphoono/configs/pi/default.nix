{
  userapps.development.agents.pi = {
    userSettings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
    };

    context = ./AGENTS.md;

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
