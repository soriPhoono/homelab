{lib, ...}:
with lib; {
  imports = [
    ./skills.nix
  ];

  config = mkMerge [
    {
      userapps.development.agents.hermes = {
        enable = true;
        enableDesktop = true;
        soulDoc = ./SOUL.md;
        userDoc = ./USER.md;

        env = {
          OPENROUTER_API_KEY.secret = "api/OPENROUTER_API_KEY";
          EXA_API_KEY.secret = "api/EXA_API_KEY";
          GH_TOKEN.secret = "api/GITHUB_API_KEY";
          OPENCODE_GO_API_KEY.secret = "api/OPENCODE_API_KEY";
          TERMINAL_ENV = "docker";
        };
      };
    }
  ];
}
