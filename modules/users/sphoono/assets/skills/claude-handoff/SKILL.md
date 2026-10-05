---
name: claude-handoff
description: Hand implementation work to Claude Code by writing a plan file to a project's .agents/plans/ directory. Use when research shows a project should change, or when the user asks you to have Claude build, fix or set up something. Never implement it yourself.
---

# Claude handoff

You hand implementation to Claude Code through a **plan file**. Each
repository being automated has its own Claude session in loop mode; it
claims the pending plans for that repository and gives each to a subagent
working in its own git worktree. The plan is the whole contract: the
subagent sees nothing else from you.

## Before writing a plan

A plan that ignores the target repository's conventions is rejected or
implemented wrongly. Read, in this order:

1. The target repository's `AGENTS.md` (or `CLAUDE.md`). Its conventions,
   verification gates and anti-patterns bind the plan: where code goes,
   what counts as passing, what must not be done.
2. The project's Notion page and its open tasks, from the request or a
   Notion search: what the user is working towards and has already
   decided.
3. mem0, with the `mem0-search` skill, for earlier decisions, failed
   approaches and constraints in the area the plan touches.

Cite what shaped the plan in its Context section. Where Notion or mem0
contradicts the repository, the repository's files are current; say so in
the plan rather than following the stale note.

## Where plans go

Always write plans to the root inbox, `~/Projects/.agents/plans/`; it is
the only plan directory you are permitted to write. Name the target in the
frontmatter, exactly one of:

- An existing repository: `target_repo: <repo>`, its directory name under
  `~/Projects/`.
- A new project: `new_repo: <name>`. These are started by the user, not a
  loop.

A plan with neither is rejected. The per-repository
`~/Projects/<repo>/.agents/plans/` directories are for plans the user
writes by hand; do not write there.

Name the file `<YYYY-MM-DD>-<slug>.md`, with a kebab-case slug describing
the change. Create the `.agents/plans/` directory if it is missing. Plans
are gitignored; they are work items, not project history.

## One plan, one change, one repository

Each plan is one logical change in one repository, small enough to land as
one or a few conventional commits. Work spanning several repositories, or
too big for one change, becomes several plans chained with `depends_on`
(the filenames of the plans that must be `done` first); each repository's
loop only claims its own plans.

## Format

```markdown
---
title: Add Syncthing to the desktop hosts
status: pending
created: 2026-10-04
author: antigravity
base: dev
# exactly one of:
target_repo: homelab
# new_repo: my-new-project
depends_on: []
research: ["[[nix/concepts/syncthing-home-manager]]"]
---

# Add Syncthing to the desktop hosts

## Goal

What should be true when this is done, in one paragraph.

## Context

What the implementer needs to know, with wiki links and source URLs from
your research, and the AGENTS.md rules, Notion notes and memories that
shaped the plan. Include the facts; do not make them re-research.

## Requirements

- [ ] Concrete, checkable acceptance criteria.

## Constraints

Files or systems that must not change, conventions to follow.

## Out of scope

What this plan deliberately does not do.
```

- `status` is always `pending` when you write it. The watcher owns it after
  that (`claimed`, `done`, `failed`) and adds a `notion_task` link; never
  edit a plan that is not `pending`.
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
