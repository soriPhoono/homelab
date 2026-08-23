______________________________________________________________________

## name: document-workflow description: "Document creation and conversion workflow — integrates docx/pptx/xlsx/pdf skills with the file system and markitdown/pandoc MCP. Use when creating, editing, or converting documents."

# Document Workflow

Create, edit, and convert documents across formats. Integrate with the file system (`~/Shared`, `~/Documents`, `~/GoogleDrive`) and use MCP servers for format conversion.

## File System Layout

| Directory | Purpose | When to Use |
|---|---|---|
| `~/Shared` | General documents, conversions, shared files | **Default** — use unless instructed otherwise |
| `~/Documents` | Temporary or unimportant documents | Official/personal documents |
| `~/GoogleDrive` | Google Drive sync folder | Files that need Google Drive sync or uploading to Google Workspace |
| `~/Shared/Vault` | Obsidian vault — notes, wikis, daily logs | All note-taking via `personal/obsidian` MCP |
| `~/Shared/Vault/00 Wikis/` | LLM knowledge bases | Managed by the `llm-wiki` skill |

## Document Formats & Skills

Load the appropriate skill before creating or editing a document:

| Format | Skill | Use When |
|---|---|---|
| Word `.docx` | `docx` | Text documents, reports, essays, letters |
| PowerPoint `.pptx` | `powerpoint` | Presentations, slide decks, visual proposals |
| Excel `.xlsx` | `xlsx` | Spreadsheets, data tables, financial models |
| PDF | `pdf` | Creating PDFs, filling forms, merging/splitting PDFs |
| Markdown | (native) | Notes, research outputs, wiki pages |

## Format Conversion

Use MCP servers for format conversion:

| MCP Server | Conversion | Example |
|---|---|---|
| `personal/markitdown` | Any → Markdown | PDF to MD, DOCX to MD, PPTX to MD |
| `personal/pandoc` | Markdown → Any | MD to DOCX, MD to PDF, MD to HTML |

### Conversion Workflow

1. **Source format → Markdown:** Use `personal/markitdown` MCP to convert the source document to markdown for reading/editing.
1. **Edit in Markdown:** Make changes in the markdown representation.
1. **Markdown → Target format:** Use `personal/pandoc` MCP to convert the edited markdown to the target format.
1. **Save to correct directory:** Default `~/Shared` unless instructed otherwise.

## Document Creation Workflow

### 1. Determine Format

Ask or infer what format the document needs to be in:

- Report or essay → `.docx`
- Presentation → `.pptx`
- Data/spreadsheet → `.xlsx`
- Fixed-layout document → `.pdf`
- Note or research output → `.md` (in Obsidian vault)

### 2. Load the Appropriate Skill

Load `docx`, `powerpoint`, `xlsx`, or `pdf` skill. These skills contain the correct library APIs, template patterns, and formatting conventions.

### 3. Create the Document

- Deliver a minimal first draft, then refine based on feedback.
- Match existing document conventions — fonts, margins, heading styles. Inspect an existing document first if one is available.
- Use descriptive filenames with dates: `2026-08-22-quarterly-review.docx`.

### 4. Save to the Correct Directory

- Default: `~/Shared`
- Unimportant documents: `~/Documents`
- Google Drive sync: `~/GoogleDrive`
- Notes/wiki: `~/Shared/Vault` (via `personal/obsidian` MCP)

### 5. Verify Output

After creating any file, verify it exists on disk and report the absolute path. Never claim a file is created without confirming the write succeeded.

### 6. Log the Work

Update the daily note in the Obsidian vault (via `personal/obsidian` MCP) with what document was created.

## Chaining with Other Skills

- **Research:** Load `research-assist` first to gather content, then `document-workflow` to produce the output document.
- **Knowledge management:** Load `llm-wiki` to build a knowledge base, then `document-workflow` to export wiki pages as formatted documents.
