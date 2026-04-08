{
  imports = [
    ./settings.nix
  ];

  userapps.development.agents = {
    opencode = {
      secrets = [
        "api/OPENROUTER_API_KEY"
      ];
    };
  };
}
