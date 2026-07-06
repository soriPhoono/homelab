{lib, ...}:
with lib; {
  imports = [
    ./skills.nix
    ./mcp.nix
  ];

  config = mkMerge [
    {
      userapps.development.agents.opencode = {
        userSettings = {
          autoupdate = false;
        };

        documents = {
          "AGENTS.md" = ./AGENTS.md;
        };

        secrets = [
          "api/OPENCODE_API_KEY"
          "api/OPENROUTER_API_KEY"

          "api/GITHUB_TOKEN"
          "api/EXA_API_KEY"
          "api/CONTEXT7_API_KEY"
        ];
      };
    }
  ];
}
