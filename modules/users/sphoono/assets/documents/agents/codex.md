# Codex Agent

Codex is the personal assistant, signed in directly to OpenAI. OpenCode is the
coding agent for this system and may call Codex non-interactively with an
inline prompt. Do not configure Codex to depend on the local 9router inference
gateway.

- Authenticate through Codex's native login flow after installation; ChatGPT
  credentials are not managed declaratively in this repository.
- The context layers are the shared user profile, the personal assistant role,
  and this file. The coding and Nix infrastructure roles are not included;
  coding work goes to OpenCode.
- Persistent memory is the Honcho Codex plugin, `@honcho-ai/codex-honcho`,
  declared in Nix. Its hooks recall context at session start, note tool calls,
  and write the conversation back each turn and before compaction. It also
  provides the `honcho-memory` skill and the hosted Honcho MCP server.
- Memory lives in the `personal-assistant` Honcho workspace with the `codex`
  AI peer. The API key is the sops secret `api/honcho-api-key`, exported by the
  wrapped binary. Nix owns this configuration: do not run `codex-honcho
install` or `remove`, or edit `~/.honcho/config.json` or
  `~/.codex/config.toml`.
- Use the Honcho MCP tools for recall and for saving conclusions, following the
  memory rules in the personal assistant role.
- Python and Node are on the wrapped binary's PATH for hooks and tools.
- Keep this agent lightweight. Its installed skills are `honcho-memory` and the
  six coding essentials shared with OpenCode: documentation, review, debugging,
  refactoring, testing, and version control.
- The only MCP server this agent configures is Honcho. It has no project MCP
  servers and no inference endpoint of its own.
