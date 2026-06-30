{lib, ...}:
with lib; {
  imports = [
    ./mcp.nix
    ./profiles.nix
  ];

  config = mkMerge [
    {
      userapps.development.agents.hermes = {
        soulDoc = ./SOUL.md;
        userDoc = ./USER.md;

        providers.opencode.enable = true;
      };
    }
  ];
}
