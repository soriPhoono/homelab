{
  imports = [
    ./settings.nix
  ];

  userapps.development.agents.opencode = {
    enable = true;
    secrets = [
      "api/OPENROUTER_API_KEY"
    ];
  };
}
