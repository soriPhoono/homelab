______________________________________________________________________

## name: research-assist description: "Research assistant skill — MCP server guidance, APA 7 citation standards, and knowledge chaining into llm-wiki and Composio. Use when conducting research on any topic."

# Research Assistant

Conduct structured research using MCP servers, cite sources in APA 7 format, and chain results into knowledge bases and document uploads.

## MCP Servers

| MCP Server | Purpose | When to Use |
|---|---|---|
| `personal/arxiv` | Query arXiv for scientific papers | Academic research, ML/AI papers, physics, CS theory |
| `personal/wikipedia` | Query Wikipedia for general knowledge | Background context, biographical research, historical events, definitions |
| `personal/sequential-thinking` | Multi-step reasoning | Breaking down complex research questions, evaluating evidence, synthesizing findings |
| `personal/obsidian` | Read/write Obsidian vault | Saving research notes, daily work logs, inter-agent handoff |
| `personal/markitdown` | Convert documents to markdown | Processing PDFs, DOCX, PPTX into research-friendly markdown |
| `personal/pandoc` | Convert markdown to other formats | Exporting research outputs to DOCX, PDF, HTML for sharing |

## Research Workflow

### 1. Define the Research Question

Use `personal/sequential-thinking` to decompose the research question into sub-questions. Identify what sources are needed (academic papers, encyclopedic background, news, primary documents).

### 2. Gather Sources

- **Scientific/academic:** Query arXiv via the `personal/arxiv` MCP server. Search by keyword, author, category, or paper ID.
- **General knowledge:** Query Wikipedia via the `personal/wikipedia` MCP server for background context, definitions, and biographical information.
- **Web sources:** Use `web_search` for news, blogs, documentation, and primary sources. Use `web_extract` to pull full content from URLs.
- **Cross-reference:** Always consult at least 2 independent sources for factual claims. Flag discrepancies explicitly.

### 3. Cite Sources (APA 7)

All research outputs must include APA 7 style citations. Format examples:

**Journal article:**

> Author, A. A., & Author, B. B. (2026). Title of article. *Journal Name*, *12*(3), 45–67. https://doi.org/10.1234/example

**arXiv preprint:**

> Author, A. A. (2026). *Title of paper*. arXiv. https://arxiv.org/abs/2601.12345

**Wikipedia:**

> Title of article. (2026, August 22). In *Wikipedia*. https://en.wikipedia.org/wiki/Title_of_article

**Web source:**

> Author, A. A. (2026, August 22). *Title of page*. Site Name. https://example.com/page

**News article:**

> Author, A. A. (2026, August 22). Title of article. *News Outlet*. https://newsoutlet.com/article

Every factual claim in a research deliverable must have a citation. Uncited claims are incomplete work.

### 4. Synthesize and Output

Based on the research goal, chain into the appropriate output skill:

- **Knowledge base:** Load the `llm-wiki` skill. Ingest sources into the wiki at `~/Shared/Vault/00 Wikis/`. Create entity and concept pages with cross-references. The wiki compounds over time — always check existing pages before creating new ones.
- **Essay/article:** Write a markdown document with APA 7 citations. Save to `~/Shared` by default.
- **Google Docs upload:** Use Composio (`composio` CLI) to upload the markdown document to Google Docs for sharing/viewing. Convert with `personal/pandoc` MCP to DOCX first if needed.
- **Research paper:** Load the `research-paper-writing` skill for formal academic paper structure.
- **Grounded citations:** Load the `grounded-citations` skill to verify all citations resolve to real, accessible sources.

### 5. Log the Work

Update the daily note in the Obsidian vault (via `personal/obsidian` MCP) with 4-5 bullets on what research was accomplished.

## Example: Researching the French Government Under Napoleon

1. **Deccompose** with sequential-thinking: What are the key figures, institutions, policies, and timeline?
1. **Gather:** Query Wikipedia for "French Consulate", "Napoleon", "Constitution of the Year VIII". Query arXiv for historical analyses. Use `web_search` for primary documents.
1. **Cite:** Format all sources in APA 7.
1. **Wiki:** Load `llm-wiki`. Ingest sources. Create entity pages for Napoleon, Talleyrand, Fouché. Create concept pages for the Consulate, the Code Napoléon, the Continental System.
1. **Synthesize:** Write a markdown essay synthesizing the wiki pages. Save to `~/Shared/napoleon-government-essay.md`.
1. **Upload:** Convert to DOCX via `personal/pandoc` MCP. Upload to Google Docs via Composio.
1. **Log:** Update the daily note in the Obsidian vault.

## Pitfalls

- **Uncited claims:** Every factual statement needs a citation. If you can't find a source, say so explicitly.
- **Single-source reliance:** Never base a factual claim on a single source unless no alternative exists (and flag this explicitly).
- **Wikipedia as primary source:** Wikipedia is a starting point for background, not a citable source for academic claims. Trace claims to their footnotes and cite the original source.
- **Forgetting to log:** Always update the daily note in the Obsidian vault after completing research work.
