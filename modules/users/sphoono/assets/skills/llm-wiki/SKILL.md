---
name: llm-wiki
description: Read, write and maintain the shared agent wiki at $AGENT_WIKI, an Obsidian vault of per-domain LLM wikis. Use before answering any factual question (check what the wiki already knows), whenever research produces something worth keeping, and when creating or reorganising wiki pages or domains.
---

# LLM wiki

`$AGENT_WIKI` (`~/Shared/AgentWiki`) is one Obsidian vault holding one wiki
per **domain**: a subject area such as `nix`, `desktop-linux` or
`video-production`. Every project's research lands here, so knowledge
compounds across projects instead of being re-derived in each one.

## Layout

```text
$AGENT_WIKI/
  index.md              # domain table + project -> domains map
  log.md                # append-only operation log
  <domain>/
    index.md            # catalog: one line per page
    raw/<slug>.md       # one captured source page, never edited after capture
    entities/<name>.md  # one named thing (a tool, module, project, API)
    concepts/<name>.md  # one idea or relationship between things
```

All file and directory names are kebab-case and named after the subject,
never after the task that prompted the research.

## Before writing: read

1. Read `$AGENT_WIKI/index.md`, then the `index.md` of each matching domain.
2. Read the 3-5 most relevant pages. If they answer the question, cite them
   and stop. **Cite an existing page rather than re-deriving it**; a second
   article on the same subject drifts into contradiction.
3. If the wiki does not cover it, say so, then research.

## Choosing a domain

- Reuse an existing domain whenever the subject fits one.
- Create a new domain only when none fits. Create its `index.md`, `raw/`,
  `entities/` and `concepts/`, and add a row to the domain table in the root
  `index.md` in the same change.
- When research serves a project, add or update that project's row in the
  root index's project -> domains map.

## Page shapes

**raw/** — capture with the `defuddle` skill. Start the file with the page
title as a top-level heading, then:

```markdown
Source: <https://example.org/page>
Retrieved: 2026-10-04
```

Raw pages are evidence. Never edit them after capture; capture again under a
new slug if the source changed.

**entities/** and **concepts/** — write with the `obsidian-markdown` skill.

```markdown
---
tags: [domain-name]
sources: ["[[raw/slug]]", "https://example.org/page"]
updated: 2026-10-04
---

# Name

One-line definition of what this is.

Body: facts, each traceable to a source in `sources`.

## In <project>

How a specific project uses it: paths, options, decisions.
```

- Open every entity and concept with a one-line definition.
- Keep project-specific detail under an `## In <project>` heading so the
  general part stays reusable by other projects.
- Link pages with wikilinks: `[[nix/entities/den|den]]` across domains,
  `[[den]]` within one.

## Keeping it consistent

- **Conflicts:** when a new source contradicts a page, do not overwrite
  silently. Add a `## Conflicts` section naming both sources and what
  differs, and mark which is current if you can tell.
- **Gaps:** when you could not verify something, write that down in the page
  instead of guessing.
- **Indexes:** after adding or renaming pages, update the domain `index.md`
  (one line per page: link and summary).
- **Log:** append one line per operation to `$AGENT_WIKI/log.md`:
  `- 2026-10-04 ingest nix: [[nix/raw/den-aspects]] (project: homelab)`.
