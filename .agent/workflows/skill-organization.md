______________________________________________________________________

## description: How to organize and distinguish between core (global) and workspace (project-specific) skills

# Skill Organization

Skills are divided into two categories based on their scope and applicability.

## Core Skills (Global)

**Location**: `~/.gemini/skills/` or `~/.config/gemini-cli/skills/`

Core skills are **language-specific** or **tool-specific** capabilities that apply across ALL projects. These should be installed globally so they're available in any workspace.

### Examples of Core Skills

| Skill | Description |
|-------|-------------|
| `nix-repl` | Evaluate Nix expressions interactively |
| `python-repl` | Debug Python code in iPython/bpython |
| `node-repl` | Test JavaScript in Node.js REPL |
| `rust-cargo` | Cargo build/test patterns |
| `git-advanced` | Complex git operations |

### When to Create a Core Skill

- The skill is **language-specific** (Nix, Python, Rust, etc.)
- The skill uses **standard tooling** (REPL, linter, formatter)
- The skill is **not project-dependent** - it works the same everywhere
- You want the skill available in **any project** using that language

## Workspace Skills (Project-Specific)

**Location**: `<project>/.agent/skills/`

Workspace skills are **project-specific** capabilities that only make sense within this particular codebase.

### Examples of Workspace Skills

| Skill | Description |
|-------|-------------|
| `deploy-staging` | How to deploy THIS app to staging |
| `database-migrations` | THIS project's migration patterns |
| `test-fixtures` | THIS project's test data setup |
| `architecture-patterns` | THIS codebase's specific patterns |

### When to Create a Workspace Skill

- The skill references **project-specific paths** or configurations
- The skill uses **custom scripts** from this repo
- The skill documents **project conventions** or patterns
- The skill would **not work** in other projects

## Decision Flowchart

```
Is this skill language/tool specific?
├─ YES → Could it work in ANY project using this language?
│        ├─ YES → CORE SKILL (~/.gemini/skills/)
│        └─ NO  → WORKSPACE SKILL (.agent/skills/)
└─ NO  → Is it about THIS project's specific setup?
         ├─ YES → WORKSPACE SKILL (.agent/skills/)
         └─ NO  → Probably a WORKFLOW, not a skill
```

## Moving a Skill from Workspace to Core

If you realize a workspace skill should be core:

1. Copy the skill to the core location:

   ```bash
   cp -r .agent/skills/<skill-name> ~/.gemini/skills/
   ```

1. Remove project-specific references from the skill

1. Delete the workspace copy:

   ```bash
   rm -rf .agent/skills/<skill-name>
   ```

## Current Core Skills to Install

The following skills from this workspace should be moved to core:

- [x] `nix-repl` - Generic Nix REPL usage (installed at `~/.gemini/skills/nix-repl/`)
