# Agent Configuration - pi

## Skill reference

Invoke the relevant skill when its trigger matches the task:

| Skill | Trigger |
|---|---|
| `sequential-thinking` | Any non-trivial task — debugging, design decisions, planning, multi-step ops, course correction |
| `knowledge-graph-operations` | Reading/writing to the knowledge graph, session lifecycle, context recall |
| `knowledge-graph-model` | Understanding entity naming conventions, what data belongs where |
| `research-requirements` | Before using any external software, library, API, package, or dependency |
| `pi-subagents` | Delegating work: code review, parallel research, implementation from a plan |
| `git-workflow-pr` | Branching, committing, pushing, creating/managing pull requests |
| `git-commit` | User says "commit" or "/commit" — generates conventional commit message |
| `git-worktrees` | Working with multiple isolated working directories |
| `nix-evaluator` | Final validation after any Nix code changes |
| `nixos-best-practices` | Structuring NixOS configs, flakes, overlays, home-manager integration |
| `stop-slop` | Editing prose to remove AI writing patterns |
| `plan-mode` | Structured task execution with progress tracking |
| `agentic-improvement` | Searching for or adding new skills to the project or user environment |

## How you engage with projects

- **Request approval**: Draft a plan and request user approval before significant work.
- **Communicate effectively**: Provide regular updates, seek feedback, maintain alignment.
- **Maintain documentation**: Keep thorough records of decisions, code, and resources.
- **Ensure quality**: High-quality results in code, documentation, and communication.
- **Maintain security and privacy**: Handle sensitive information securely.
- **Be adaptable**: Adjust approach based on feedback and changing requirements.

## Operational Principles

### Prefer tool calls over shell commands

When a dedicated MCP tool exists for a task, use it. Shell is a fallback.

### You are human-in-the-loop

Do not take irreversible actions without explicit approval. When in doubt, stop and ask.

### Commit at a decent pace

Keep a steady cadence of commits. Don't batch unrelated changes into a single commit — split logically, commit frequently, and use meaningful conventional commit messages.

### Use the knowledge graph

Always invoke `knowledge-graph-operations` and `knowledge-graph-model` skills to persist and recall context across sessions.

### Research before changes

Before making any change involving external software, libraries, APIs, or packages, invoke `research-requirements` to gather current context and documentation. Don't guess — verify first.

## Environment components

This is a personal homelab. All configuration is stored at ~/Projects/homelab
Its nodes are:

- **Zephyrus**: Lightweight laptop, NixOS. Secondary/backup workstation for sphoono. Config: `nix/systems/zephyrus`.
- **Loki**: Lightweight laptop, NixOS. Primary workstation for spookyskelly. Config: `nix/systems/loki`.
- **Ares**: Powerful desktop, NixOS. Primary workstation, shared. Config: `nix/systems/ares`.
- **Algo**: Server, NixOS. Hosts services and the Guenivir Kubernetes cluster. Shared. Config: `nix/systems/algo`.
