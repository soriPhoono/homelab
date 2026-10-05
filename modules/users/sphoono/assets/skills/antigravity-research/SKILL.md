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
  --add-dir "${AGENT_WIKI:-$HOME/Shared/AgentWiki}" \
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

`AGENT_WIKI` is unset in sessions started before the last Home Manager
switch, hence the fallback. Research takes about five minutes. Run the
command in the background and keep working on what does not depend on it.

## Reading the result

agy may print plain-text warnings before the JSON envelope, so select the
envelope line. The research result is its `response` field, a JSON string
matching `result.schema.json`:

```sh
envelope="$(grep '^{' <<<"$output" | tail -n 1)"
jq '{status, error, denied_actions}' <<<"$envelope"
jq -r '.response | fromjson' <<<"$envelope"
```

- **A failed run can report `"status": "SUCCESS"`.** Treat it as failed when
  `status` is `"ERROR"`, `error` is non-empty, `response` is empty, or
  `denied_actions` is non-null.
- `authentication required` means the user must run `agy` once in a
  terminal to log in; tell them and stop retrying.
- `denied_actions` means a tool needed a permission headless mode cannot
  grant. Report the action and the warning line above the envelope (it
  names the permission) to the user. The allow rules are in
  `~/.gemini/antigravity-cli/settings.json`, managed from Home Manager.
- The result can carry extra keys beyond the schema; ignore them.
- `findings[].confidence` is `high`, `medium` or `low`. Treat `low` as a
  lead, not a fact.
- `wiki_pages` are paths under `$AGENT_WIKI`; read them for detail.
- An `open_questions` entry of the form `plan: <path>` is an
  implementation plan agy wrote for the plan watcher. Mention it to the user.

## Verifying the result

agy cannot run `nix` or `git`, and on its first real topic 8 of 19 "high"
confidence findings were wrong: packages it called missing were in
nixpkgs, a release date was reported as an archival date, and it invented
deployments for the project. Before reporting, check every claim of these
kinds yourself, against the project's pinned inputs:

- **nixpkgs attributes**, from the project directory:

  ```sh
  nix eval --impure --raw --expr '
    let p = import (builtins.getFlake (toString ./.)).inputs.nixpkgs {
          system = builtins.currentSystem; config.allowUnfree = true; };
    in if p ? "<attr>" then p."<attr>".version else "MISSING"'
  ```

  An attribute can be named differently from the project (`bitcoind`,
  `python3Packages.<name>`); before calling something missing, also try
  `nix search` on the same nixpkgs.

- **NixOS and Home Manager options**: `builtins.hasAttr` on
  `nixosConfigurations.<host>.options` or the home configuration's
  `options`.
- **Repository status**:
  `gh api repos/<owner>/<repo> --jq '{archived, pushed_at}'`.
- **Project usage**: `git -C ~/Projects/<project> grep -n <name>`.

Correct the wiki for every claim that fails, following the `llm-wiki`
conflict rule: fix the page, add a `## Conflicts` note naming the check
you ran, and append a `log.md` entry. Drop the `(unverified)` marker from
claims that pass.

Report findings with their sources, and say which ones you verified. Do not
restate a `low` confidence or unverified finding as settled.
