{
  imports = [
    ./settings.nix
    ./mcp.nix
  ];

  userapps.development.agents = {
    opencode = {
      secrets = [
        "api/OPENROUTER_API_KEY"

        "api/EXA_API_KEY"
        "api/CONTEXT7_API_KEY"
        "api/GITHUB_API_KEY"
      ];
    };
  };
}
