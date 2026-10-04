---
name: plan-watch
description: One pass of the implementation-plan watcher. Scans ~/Projects/.agents/plans/ and ~/Projects/*/.agents/plans/ for pending plans, claims them, and runs one subagent per plan in its own git worktree. Use when invoked as /plan-watch, typically from `/loop 15m /plan-watch` in a session started in ~/Projects.
---

# Plan watch

Each invocation is one pass over the plan directories. Plans are written by
Antigravity's `claude-handoff` skill (or by the user) in the format that
skill defines. This session orchestrates; subagents implement.

## 1. Find work

```sh
grep -l '^status: pending' \
  ~/Projects/.agents/plans/*.md ~/Projects/*/.agents/plans/*.md 2>/dev/null
```

Take plans oldest first by filename date. Skip a plan whose `depends_on`
lists a plan that is not `done` yet. If nothing is pending, report "no
pending plans" in one line and end the pass.

Run at most **3** subagents at once. Leave the rest pending for a later
pass.

## 2. Validate and claim

Resolve the target from the plan's location:

- `~/Projects/<repo>/.agents/plans/` targets `<repo>`.
- `~/Projects/.agents/plans/` needs exactly one of `new_repo` or
  `target_repos`. With neither, set `status: failed` and a `## Result`
  saying why, and move on.

Claim before doing anything else, so a retry never starts the same plan
twice: set `status: claimed` and add `claimed: <ISO timestamp>` to the
frontmatter.

## 3. Prepare the worktree

`base` defaults to `dev`. For each target repository:

```sh
git -C ~/Projects/<repo> fetch origin
git -C ~/Projects/<repo> rev-parse --verify origin/<base>
git -C ~/Projects/<repo> worktree add -b handoff/<slug> \
  ~/Projects/.worktrees/<repo>/<slug> origin/<base>
```

`<slug>` is the plan filename without the date prefix and `.md`. If
`origin/<base>` does not exist, fail the plan: say which base was missing.
Do not fall back to another branch. If the `handoff/<slug>` branch already
exists, fail the plan as a possible earlier run and leave the branch alone.

For `new_repo`, create `~/Projects/<name>`, `git init -b <base>` it, and
work there directly on `handoff/<slug>`.

For `target_repos`, prepare one worktree per repository and run one
subagent per repository.

## 4. Dispatch

Start one background subagent per worktree with the Agent tool. Give it
the plan path, the worktree path and these rules verbatim:

> Implement the plan at `<plan path>` in the worktree at `<worktree path>`,
> and only there. Read the repository's AGENTS.md or CLAUDE.md first and
> follow it, including its verification gates. Commit with conventional
> commits; never pass `--no-verify`. Never push, merge, deploy, run
> `nixos-rebuild`, `home-manager switch` or `nh`, and never touch secrets.
> Do not edit the plan file. Finish with: the branch name, the commit list,
> the verification output, whether every requirement in the plan is met,
> and any open questions.

## 5. Record the result

When a subagent reports back, this session (never the subagent) updates the
plan, so only one writer touches it:

- `status: done` if every requirement is met and the gates passed,
  otherwise `status: failed`.
- Add `finished: <ISO timestamp>`.
- Append a `## Result` section: branch, commits, verification output
  (trimmed to what matters), unmet requirements, open questions. For
  `target_repos`, one subsection per repository.

Then tell the user in one line per plan: plan, status, branch. The user
reviews the branch, opens any PR and deploys; this watcher never does.

## Claimed plans with no subagent

A plan left `claimed` by an earlier session that ended mid-run is not
retried automatically. List it to the user with its `claimed` time and the
branch, if any, and leave it for them to reset to `pending` or close.
