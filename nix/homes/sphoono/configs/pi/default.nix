{
  userapps.development.agents.pi = {
    userSettings = {
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
    };

    context = {
      system = ./SYSTEM.md;
      user = ./AGENTS.md;
    };

    packages = [
    ];
  };
}
