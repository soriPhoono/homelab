# Codex Agent

Codex is the direct OpenAI fallback when the local 9router inference gateway is
unavailable or under maintenance. Do not configure Codex to depend on 9router.

- Authenticate through Codex's native login flow after installation; credentials
  are not managed declaratively in this repository.
- Reuse the shared user profile, coding role, and Nix infrastructure role
  already used by OpenCode. Keep agent-specific operating rules in this file;
  OpenCode-only integrations do not apply to Codex.
- Persistent memory is the mem0 Codex plugin, matching the Claude Code setup.
  Its lifecycle hooks recall context at session start and capture the session
  on stop, and it exposes the `/mem0` skills and memory MCP server. The API key
  comes from the SOPS secret `api/mem0-api-key` through the wrapped binary.
- Keep this agent lightweight. Its installed skills are the six coding
  essentials shared with OpenCode: documentation, review, debugging,
  refactoring, testing, and version control.
- This agent does not configure project MCP servers or its own inference
  endpoint.
