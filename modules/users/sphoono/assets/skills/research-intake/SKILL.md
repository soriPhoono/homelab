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
- **project** — the project the research serves, if any.
- **context** — what Claude already knows; do not re-research it.

If the question is ambiguous, research the most useful reading and record
the ambiguity in `open_questions`. There is no one to ask mid-run.

## Procedure

1. **Check the wiki first** with the `llm-wiki` skill. If it already answers
   the question, return those pages and stop.
2. **Search.** Prefer primary sources: official docs, source code, release
   notes, specifications. Treat blogs and forums as leads to a primary
   source, not as evidence on their own.
3. **Capture** each source you rely on into `<domain>/raw/` with the
   `defuddle` skill.
4. **Distil** findings into `entities/` and `concepts/` pages, following the
   `llm-wiki` skill. Update the indexes and `log.md`.
5. **Verify claims** one by one when asked to: mark each confirmed,
   contradicted or unverifiable, with the source that decides it.
6. **Stop** when the question is answered, or after about 15 sources without
   convergence. Report what remains open rather than searching forever.

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
