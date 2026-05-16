---
name: agentic-improvement
description: This skill assists in searching for and adding skills at both project (repo) level and agent (user) level scope. Use this whenever you want to add skills to this repository or the user environment.
---

# Agentic Improvement

## Overview

This skill guides the discovery and installation of agent skills from the Open Agent Skills Ecosystem. It distinguishes between two scopes of skills and provides the correct workflow for each.

## Skill Scopes

### Project-Level Skills

Project-level skills have **limited scope** — they are tied to this specific repository and its codebase. Examples include Nix evaluation workflows, deployment procedures, or repository-specific conventions.

**Characteristics:**
- Bound to `.agents/skills/` in this repository
- Provide guidance specific to this codebase, architecture, or workflows
- Do not require nix-skills packaging — simple discovery via `find-skills` is sufficient

**Workflow:**
1. Use the `find-skills` skill to search for relevant capabilities
2. Create the skill directory under `.agents/skills/<skill-name>/`
3. Write the `SKILL.md` with frontmatter and workflow instructions
4. The skill is immediately available to all agents working in this repository

### Agent-Level Skills

Agent-level skills are **abstract and general** — they are about working with code, not specifically this code. Examples include frontend design patterns, testing methodologies, or general refactoring techniques.

**Characteristics:**
- Installed as nix packages via `nix-skills` for reproducible, version-pinned delivery
- Available across all agent environments (user-level or system-wide)
- Decoupled from any single repository

**Workflow:**
1. Use the `find-skills` skill to search the Skills ecosystem (skills.sh)
2. Identify the skill's **owner**, **repo**, and **name** from the search results
3. Reference the skill as a nix package in the format:
   ```nix
   pkgs.<owner>.<repo>.<name>
   ```
   For example, a skill from `vercel-labs/skills` named `find-skills` becomes:
   ```nix
   pkgs.vercel-labs.skills.find-skills
   ```
4. Add the derivation to the appropriate skills configuration:
   - **User-level:** `nix/homes/sphoono/configs/agents/skills.nix`
   - **System-wide module:** `nix/modules/home/userapps/development/agentics/agents/skills.nix`
5. Validate with `nix flake check`

## When to Use Each Scope

| Criteria | Project-Level | Agent-Level |
|---|---|---|
| Scope | This repository only | Any codebase |
| Content | Repo-specific workflows | General coding practices |
| Installation | `.agents/skills/` directory | nix-skills package |
| Reproducibility | Git-tracked | Nix-pinned derivation |
| Example | Nix evaluation workflow | React best practices |

## Decision Tree

```
Is this skill about THIS codebase specifically?
  ├── Yes → Project-Level Skill
  │         → Use find-skills for inspiration, write SKILL.md in .agents/skills/
  │
  └── No → Agent-Level Skill
            → Use find-skills to locate on skills.sh
            → Extract owner/repo/name
            → Add as pkgs.<owner>.<repo>.<name> to skills.nix
```
