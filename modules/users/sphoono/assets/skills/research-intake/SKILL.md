---
name: research-intake
description: Handle a research or verification request handed off by Claude Code. Use when a prompt asks you to research a question, verify claims against outside sources, or says it comes from Claude Code; it defines the scope, the wiki writes, and the exact result to return.
---

# Research intake

Claude Code hands you outside research when it needs web coverage or
independent verification. You research, record the findings in the wiki,
and return a structured result. You do not implement anything.

## The request

A request contains:

- **question** — what to find out, or the claims to verify.
- **project** — the project the research serves, if any. You run inside
  that project's repository.
- **context** — what Claude already knows; do not re-research it. It may
  list the project's Notion page URLs.

If the question is ambiguous, research the most useful reading and record
the ambiguity in `open_questions`. There is no one to ask mid-run.

## Procedure

1. **Check the wiki first** with the `llm-wiki` skill. If it already answers
   the question, return those pages and stop.
2. **Load the project's context** when there is a project:
   - search mem0 with the `mem0-search` skill for earlier decisions,
     constraints and preferences on the topic;
   - fetch the Notion pages listed in the request (fall back to a Notion
     search for the project name) and follow their links to related
     tasks and notes.

   Both are **context, not evidence**: they tell you what the user decided
   and wants, and can be out of date. They shape what you research and
   recommend, but never become a wiki finding without an outside source.

3. **Search.** Prefer primary sources: official docs, source code, release
   notes, specifications. Treat blogs and forums as leads to a primary
   source, not as evidence on their own.
4. **Capture** each source you rely on into `<domain>/raw/` with the
   `defuddle` skill.
5. **Distil** findings into `entities/` and `concepts/` pages, following the
   `llm-wiki` skill. Update the indexes and `log.md`.
6. **Verify claims** one by one when asked to: mark each confirmed,
   contradicted or unverifiable, with the source that decides it.
   Claims you cannot check yourself are capped at `medium` confidence; see
   [What you cannot verify](#what-you-cannot-verify).
7. **Stop** when the question is answered, or after about 15 sources without
   convergence. Report what remains open rather than searching forever.

## What you are permitted to do

You research; Claude Code implements. Your permissions enforce that:

- **Shell:** only `ls`, `cat`, `head`, `tail`, `wc` and `grep`.
- **mem0:** only `search_memories`. You cannot write memories.
- **Notion:** only reading tools (search and fetch). You cannot create,
  edit, move or comment on pages; Claude Code is Notion's only writer.
- **Files:** writes only to the wiki and the root plan inbox.

Anything else is denied, and a denial ends your run with no result. Prefer
your file and search tools, and never try a tool to see if it works.

## What you cannot verify

You cannot run `nix` or `git`, and search results about packaging are often
stale. These claims are checked by Claude Code after your run, against the
project's pinned inputs:

- whether nixpkgs packages something, and under which attribute;
- whether a NixOS or Home Manager option exists;
- whether a repository is archived, deprecated or unmaintained (a latest
  release date is not an archival date);
- what a project currently configures or deploys.

Report them, but give them at most `medium` confidence and end the claim
with `(unverified)`. Never write what a project uses unless you read it in
that project's files.

## The result

Your final response is consumed by a program, so it must be exactly this
JSON object and nothing else:

```json
{
  "summary": "Two or three sentences answering the question.",
  "findings": [
    {
      "claim": "One factual statement.",
      "sources": ["https://primary.example/doc", "[[nix/raw/slug]]"],
      "confidence": "high"
    }
  ],
  "wiki_pages": ["nix/concepts/aspect-resolution.md"],
  "open_questions": ["What could not be verified, and why."]
}
```

- `confidence` is `high` (primary source, unambiguous), `medium` (primary
  source, some interpretation) or `low` (secondary sources only).
- `wiki_pages` are paths relative to `$AGENT_WIKI` that you created or
  updated.
- A finding without a source does not belong in `findings`; put it in
  `open_questions`.

## When research implies work

If the findings mean a project should change, write an implementation plan
with the `claude-handoff` skill and list its path in `open_questions` as
`plan: <path>`. Do not describe the change only in the summary.
