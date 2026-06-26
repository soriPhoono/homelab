{lib, ...}:
with lib; {
  config = mkMerge [
    {
      userapps.development.agents.hermes = {
        enable = true;
        soulDoc = ./SOUL.md;
        userDoc = ./USER.md;
      };
    }
  ];
}
