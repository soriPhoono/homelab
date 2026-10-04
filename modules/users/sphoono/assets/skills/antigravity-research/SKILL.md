---
name: antigravity-research
description: Hand outside research or fact verification to Antigravity CLI (agy), which searches the web with Google Search grounding on Gemini quota and records findings in the shared agent wiki. Use for broad web sweeps, comparing options across many sources, or checking claims against outside sources. Not for library API docs (use Context7) or pinned flake-input sources (read the nix store).
---

# Antigravity research

`agy` runs Gemini with Google Search grounding on the user's Google quota.
Delegating broad web research to it is cheaper than doing it here and
covers the web better. It records what it finds in the shared wiki at
`$AGENT_WIKI` and returns a structured result.

## When to delegate

- **Delegate:** surveys across many sources, "what are the options for X",
  current state of a project or ecosystem, verifying claims you or the user
  made against outside sources.
- **Do not delegate:** library or framework API docs (Context7), anything
  answerable from the nix store or the repository, or a single known URL
  (fetch it yourself).

Check the wiki first: read `$AGENT_WIKI/index.md` and the relevant domain's
`index.md`. If it already answers the question, cite it instead of running
agy.

## Running it

Run from `~/Projects` so agy sees every project, and give it the wiki:

```sh
cd ~/Projects && agy -p "$prompt" \
  --sandbox \
  --add-dir "$AGENT_WIKI" \
  --output-format json \
  --json-schema ~/.claude/skills/antigravity-research/result.schema.json \
  --print-timeout 20m
```

Write the prompt so agy's `research-intake` skill can act on it alone:

```text
Research request from Claude Code (use the research-intake skill).
Question: <what to find out, or the numbered claims to verify>
Project: <project name, or none>
Context: <what is already known; do not re-research it>
```

Research takes minutes. Run the command in the background and keep working
on what does not depend on it.

## Reading the result

The command prints an envelope; the research result is the `response`
field, a JSON string matching `result.schema.json`:

```sh
jq -r '.response | fromjson' <<<"$output"
```

- `status` of `"ERROR"`, or a non-empty `error`, means the run failed.
  `authentication required` means the user must run `agy` once in a
  terminal to log in; tell them and stop retrying.
- `findings[].confidence` is `high`, `medium` or `low`. Treat `low` as a
  lead, not a fact.
- `wiki_pages` are paths under `$AGENT_WIKI`; read them for detail.
- An `open_questions` entry of the form `plan: <path>` is an
  implementation plan agy wrote for the plan watcher. Mention it to the user.

Report findings with their sources. Do not restate a `low` confidence
finding as settled.
