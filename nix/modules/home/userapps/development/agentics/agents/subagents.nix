{lib, ...}:
with lib; {
  options.userapps.development.agentics.agents.subagents = {
    registry = mkOption {
      type = types.attrsOf (types.either types.str types.path);
      default = {};
      description = ''
        Registry of subagent definitions shared across all agents.
        Each key is the subagent name (usable via @name in the TUI),
        each value is markdown content with YAML frontmatter.

        Values can be inline strings or paths to `.md` files
        (including derivations from `pkgs.fetchFromGitHub`).

        Agent modules read this and map it to their built-in agents option
        (e.g. `programs.opencode.agents`).
      '';
      example = {
        code-reviewer = ''
          ---
          description: Reviews code for best practices and potential issues
          mode: subagent
          permission:
            edit: deny
          ---

          You are in code review mode. Focus on:
          - Code quality and best practices
          - Potential bugs and edge cases
          - Performance implications
          - Security considerations
        '';
      };
    };
  };
}
