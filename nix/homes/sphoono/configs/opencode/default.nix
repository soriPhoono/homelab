{
  lib,
  pkgs,
  config,
  ...
}: let
  modulePath = "userapps.development.agents.opencode";
  cfg = config.${modulePath};
  # MCP servers are shared via userapps.development.agentics
  # (defined in nix/homes/sphoono/configs/pi/mcp.nix).
in
  with lib; {
    options.${modulePath} = {
      enable = mkEnableOption "Enable this module";
    };

    config = mkIf cfg.enable (mkMerge [
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

          skills = {
            create-agentsmd = pkgs.skills.github.awesome-copilot.create-agentsmd;

            stop-slop = pkgs.skills.hardikpandya.stop-slop.stop-slop;

            git-commit = pkgs.skills.github.awesome-copilot.git-commit;
          };
        };
      }
    ]);
  }
