# mem0's official Claude Code plugin: hooks that write memories from each
# session and search them on later prompts, keyed by the repository's git
# remote, plus an MCP server and /mem0 skills. It reads MEM0_API_KEY, which
# the claude wrapper in ../default.nix exports from this secret.
{ inputs }:
_: {
  programs.claude-code.plugins.mem0 = "${inputs.mem0}/integrations/claude-code-plugin";

  sops.secrets."api/mem0-api-key" = { };
}
