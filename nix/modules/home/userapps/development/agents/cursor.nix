{
  lib,
  pkgs,
  config,
  ...
}: let
  agentsCfg = config.userapps.development.agentics.agents;
  cfg = config.userapps.development.agents.cursor;
in
  with lib; {
    options.userapps.development.agents.cursor = {
      enable = mkEnableOption ''
        Cursor CLI support under `~/.cursor`: CLI-specific `AGENTS.md`, optional secret wrapping for
        `cursor-cli`, and coordination with the editor module when the Cursor desktop editor is enabled.
      '';
    };

    config = mkIf cfg.enable {
      home.file = {
        ".cursor/AGENTS.md" = {
          text = ''
            # Cursor CLI Context

            This file provides machine-level and user-level context for Cursor CLI.
            Project-level repository guidance stays in the repository root
            `AGENTS.md` and `.agents/AGENTS.md`.

            ${agentsCfg.context {}}
          '';
        };
      };
      home.packages = with pkgs; [cursor-cli];
    };
  }
