{
  userapps.development.agents.opencode = {
    secrets = [
      "api/OPENROUTER_API_KEY"
      "api/OPENCODE_API_KEY"
    ];

    settings = {
      model = "opencode/deepseek-v4-flash";
      default_agent = "multi-agent-coordinator";
    };
  };
}
