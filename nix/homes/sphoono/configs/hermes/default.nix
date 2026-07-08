{
  imports = [
    ./mcp.nix
    ./profiles.nix
  ];

  apps.development.agents.hermes = {
    providers = {
      opencode.enable = true;
      ollama.models = ["gemma4:12b"];
    };

    gateways.telegram.enable = true;

    profiles.default = {
      enable = true;
      soulDoc = ./SOUL.md;
      userDoc = ./USER.md;
    };
  };
}
