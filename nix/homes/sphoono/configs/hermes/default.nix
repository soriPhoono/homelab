{
  lib,
  config,
  ...
}: let
  cfg = config.userapps.development.agents.hermes;
in
  with lib; {
    config = mkIf cfg.enable {
      userapps.development.agents.hermes = {
        enable = true;
        defaultProfile = "dev";
        soul = ./SOUL.md;
        user = ./USER.md;

        profiles = {
          dev = {
            enable = true;
            description = "Software development, code review, debugging, and engineering tasks.";
            model = "openrouter/anthropic/claude-sonnet-4";
          };

          ops = {
            enable = true;
            description = "Infrastructure, deployment, DevOps, and system administration.";
            model = "openrouter/anthropic/claude-sonnet-4";
          };

          reviewer = {
            enable = true;
            description = "Code review, quality assurance, and architectural analysis.";
            model = "openrouter/anthropic/claude-sonnet-4";
          };
        };
      };
    };
  }
