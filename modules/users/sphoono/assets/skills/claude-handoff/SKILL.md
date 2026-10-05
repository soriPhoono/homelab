---
name: claude-handoff
description: Hand implementation work to Claude Code by writing a plan file to a project's .agents/plans/ directory. Use when research shows a project should change, or when the user asks you to have Claude build, fix or set up something. Never implement it yourself.
---

# Claude handoff

You hand implementation to Claude Code through a **plan file**. A Claude
session in loop mode watches the plan directories, claims each pending plan
and gives it to a subagent working in its own git worktree. The plan is the
whole contract: the subagent sees nothing else from you.

## Where plans go

Always write plans to the root inbox, `~/Projects/.agents/plans/`; it is
the only plan directory you are permitted to write. Name the target in the
frontmatter:

- One or more existing repositories: `target_repos: [<repo>, ...]`, the
  directory names under `~/Projects/`.
- A new project: `new_repo: <name>`.

A plan with neither is rejected. The per-repository
`~/Projects/<repo>/.agents/plans/` directories are for plans the user
writes by hand; do not write there.

Name the file `<YYYY-MM-DD>-<slug>.md`, with a kebab-case slug describing
the change. Create the `.agents/plans/` directory if it is missing. Plans
are gitignored; they are work items, not project history.

## One plan, one change

Each plan is one logical change, small enough to land as one or a few
conventional commits. Split bigger work into several plans and say in each
which others it depends on.

## Format

```markdown
---
title: Add Syncthing to the desktop hosts
status: pending
created: 2026-10-04
author: antigravity
base: dev
# exactly one of:
target_repos: [homelab]
# new_repo: my-new-project
depends_on: []
research: ["[[nix/concepts/syncthing-home-manager]]"]
---

# Add Syncthing to the desktop hosts

## Goal

What should be true when this is done, in one paragraph.

## Context

What the implementer needs to know, with wiki links and source URLs from
your research. Include the facts; do not make them re-research.

## Requirements

- [ ] Concrete, checkable acceptance criteria.

## Constraints

Files or systems that must not change, conventions to follow.

## Out of scope

What this plan deliberately does not do.
```

- `status` is always `pending` when you write it. The watcher owns it after
  that (`claimed`, `done`, `failed`); never edit a plan that is not
  `pending`.
- `base` is the branch the work starts from. Leave it `dev` unless the user
  or the project says otherwise.
- Write requirements the implementer can verify by running something, not
  impressions.

## What not to do

- Do not run `claude` or any other agent yourself. Writing the plan is the
  handoff.
- Do not push, merge or deploy, and do not ask the implementer to.
- Do not put secrets or credentials in a plan. If the change needs one, say
  what is needed and that the user must provide it.
