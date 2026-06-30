{lib, ...}:
with lib; {
  imports = [
    ./skills.nix
    ./mcp.nix
  ];

  config = mkMerge [
    {
      apps.development.agents.hermes = {
        soulDoc = ./SOUL.md;
        userDoc = ./USER.md;

        providers.opencode.enable = true;
      };
    }
  ];
}
