{
  imports = [
    ./settings.nix
    ./mcp.nix
  ];

  userapps.development.agents.gemini = {
    secrets = [
      "api/EXA_API_KEY"
      "api/CONTEXT7_API_KEY"
      "api/GITHUB_API_KEY"
    ];
  };
}
