{lib, ...}:
with lib; {
  options.userapps.development.agentics.agents.commands = {
    registry = mkOption {
      type = types.attrsOf (types.either types.str types.path);
      default = {};
      description = ''
        Registry of TUI slash commands shared across all agents.
        Each key is the command name (used as `/name` in the TUI),
        each value is markdown content describing the command prompt.
        Values can be inline strings or paths to `.md` files
        (including derivations from `pkgs.fetchFromGitHub`).

        Agent modules read this and map it to their built-in commands option
        (e.g. `programs.opencode.commands`, `programs.gemini-cli.commands`).
      '';
      example = {
        commit = ''
          # Commit Command

          Create a git commit with proper message formatting.
          Usage: /commit [message]
        '';
        fix-issue = ./commands/fix-issue.md;
      };
    };
  };
}
