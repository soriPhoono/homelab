---
name: plan-watch
description: One pass of a repository's implementation-plan watcher. Claims the pending plans for the repository this session runs in, from ~/Projects/.agents/plans/ and the repository's own .agents/plans/, runs one worktree subagent per plan and tracks each in Notion. Use when invoked as /plan-watch, typically from `/loop 15m /plan-watch` in a session started in the repository.
---

# Plan watch

Each invocation is one pass for **this session's repository**. Run one loop
per repository you want automated, started inside that repository: mem0
keys memory by the repository's git remote, so a session elsewhere would
read and write the wrong memories. Plans are written by Antigravity's
`claude-handoff` skill (or by the user) in the format that skill defines.
This session orchestrates and is the only writer of the plan files and
their Notion tasks; subagents implement.

## 1. Find work

```sh
repo="$(basename "$(git rev-parse --show-toplevel)")"
grep -l -x 'status: pending' ~/Projects/.agents/plans/*.md 2>/dev/null |
  xargs -r grep -l -x "target_repo: $repo"
grep -l -x 'status: pending' .agents/plans/*.md 2>/dev/null
```

Plans in this repository's `.agents/plans/` target it implicitly. Never
claim a root plan whose `target_repo` is another repository, and leave
`new_repo` plans alone; the user starts those.

Take plans oldest first by filename date. Skip a plan whose `depends_on`
lists a plan that is not `done` yet; plans in a chain may belong to other
repositories' loops. If nothing is ready, report "no pending plans" in one
line and end the pass.

Run at most **3** subagents at once. Leave the rest pending for a later
pass.

## 2. Validate and claim

Claim before doing anything else, so a retry never starts the same plan
twice: set `status: claimed` and add `claimed: <ISO timestamp>` to the
frontmatter.

`base` defaults to `dev`. Check it exists:

```sh
git fetch origin
git rev-parse --verify "origin/<base>"
git rev-parse --verify "handoff/<slug>"   # must fail
```

`<slug>` is the plan filename without the date prefix and `.md`. If
`origin/<base>` is missing, fail the plan and say which base. Do not fall
back to another branch. If `handoff/<slug>` already exists, fail the plan
as a possible earlier run and leave the branch alone. To fail a plan, set
`status: failed`, add a `## Result` saying why, and move on.

## 3. Track it in Notion

Find the project's Tasks database the same way the session-start rule does
(the project name from the repository's AGENTS.md, then its page under
Projects). Create a row: the plan title as its name, status "In progress",
and in its body the plan path, the branch `handoff/<slug>` and the base.
Record the row's URL as `notion_task: <url>` in the plan's frontmatter.

If no Tasks database can be found, say so in the pass summary and carry
on; Notion tracking never blocks a plan.

## 4. Dispatch

Start one background subagent per plan with the Agent tool and
`isolation: "worktree"`. Give it the plan path, the base and these rules
verbatim:

> Implement the plan at `<plan path>` in your worktree, and only there.
> First run:
> `git fetch origin && git switch -c handoff/<slug> origin/<base>`.
> Read the repository's AGENTS.md or CLAUDE.md and follow
> it, including its verification gates. Commit with conventional commits;
> never pass `--no-verify`. Never push, merge, deploy, run
> `nixos-rebuild`, `home-manager switch` or `nh`, and never touch secrets.
> Do not edit the plan file or Notion. Finish with: the worktree path, the
> branch name, the commit list, the verification output, whether every
> requirement in the plan is met, and any open questions.

## 5. Record the result

When a subagent reports back, update the plan:

- `status: done` if every requirement is met and the gates passed,
  otherwise `status: failed`.
- Add `finished: <ISO timestamp>`.
- Append a `## Result` section: worktree, branch, commits, verification
  output (trimmed to what matters), unmet requirements, open questions.

Then update the Notion row: status "Done" for a done plan; for a failed
plan leave it "In progress" and add the failure reason to its body, so it
stays visible as open work. Tell the user in one line per plan: plan,
status, branch. The user reviews the branch, opens any PR and deploys;
this watcher never does.

## Claimed plans with no subagent

A plan left `claimed` by an earlier session that ended mid-run is not
retried automatically. List it to the user with its `claimed` time, its
Notion task and the branch, if any, and leave it for them to reset to
`pending` or close.
