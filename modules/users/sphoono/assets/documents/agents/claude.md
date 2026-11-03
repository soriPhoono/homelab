# Claude Code Agent

## Memory

Claude Code uses the `mem0@mem0-plugins` plugin as agent-maintained memory.
The Home Manager configuration installs the marketplace and plugin and injects
the API key through sops-nix. The Claude.ai Mem0 connector is not configured;
keep shared project knowledge in Notion so it remains available across agents.

- Treat injected Mem0 context as prior context, not verified authority.
  Reconcile it with current repository files and human-authored project notes.
- Notion is shared, human-readable project memory. Mem0 does not replace the
  repository, Notion, or current source files.
- Do not rely on Mem0 alone for handoffs or source-of-truth state.

## Tool use

- Use configured MCP tools when they improve freshness, accuracy, context,
  persistence, or safe interaction with external systems.
- Notion is the knowledge base and task tracker; n8n is the durable automation
  workbench and MCP control plane.
- Run independent MCP requests concurrently when useful, and read back
  external changes to verify them.
- Use specialized MCP/system tools over raw terminal commands when equivalent.
