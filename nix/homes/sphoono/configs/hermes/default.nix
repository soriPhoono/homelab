{lib, ...}:
with lib; {
  imports = [
    ./mcp.nix
    ./profiles.nix
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
