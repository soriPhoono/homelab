{lib, ...}:
with lib; {
  imports = [
    ./skills.nix
    ./mcp.nix
    ./tools.nix
  ];

  config = mkMerge [
    {
      userapps.development.agents.hermes = {
        soulDoc = ./SOUL.md;
        userDoc = ./USER.md;

        providers.opencode.enable = true;

        gateway.telegram.enable = true;
      };
    }
  ];
}
