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
          model = "opencode-go/deepseek-v4-flash";
          autoupdate = false;
        };

        context = ./AGENTS.md;

        secrets = [
          "api/OPENCODE_API_KEY"
          "api/OPENROUTER_API_KEY"

          "api/GITHUB_API_KEY"
          "api/EXA_API_KEY"
          "api/CONTEXT7_API_KEY"
        ];
      };
    }
  ];
}
