{
  userapps.development = {
    agentics = {
      context = {
        user = ''
          # User Workflow, Identity & Preferences: sphoono

          ## Identity & Contact
          - **Name**: soriphoono
          - **Email**: `soriphoono@gmail.com` (Primary contact for infrastructure, GitHub, and personal communication).
          - **GitHub**: `soriphoono`
          - **Bio**: Enthusiastic homelabber and infrastructure-as-code practitioner focused on declarative systems (NixOS), virtualization, and AI-assisted development.
          - **Projects**: Maintaining the "Data Fortress" homelab and exploring the intersection of AI agents and terminal-centric workflows.

          ## Shell & Terminal
          - **Primary Shell**: Fish (with Starship prompt and Fastfetch).
          - **Development**:
            - **Editors**: Zed, Zen Browser (configured with specific extensions and policies).
            - **Agents**:
              - Gemini-CLI (For frontier model inference)
              - OpenCode (For multi-model inference and complex workflows)
              - Pi Agent (For every day agentic operations, integrated with Obsidian vault management)


          ## Daily Work Log, Planner & Wiki System

          This is an integrated Obsidian-based system spanning three complementary subsystems: a daily work log (Daily Notes + Calendar), a task/todo tracker (Tasks plugin), and a research knowledge base (LLM Wiki). All live in the same vault and are accessed via the `obsidian` MCP server.

           ### Vault Location & Tooling

           - **Vault root**: `~/Nextcloud/Notes/` — an Obsidian vault synchronized via Nextcloud.
           - **Access**: The Obsidian MCP server (`obsidian` in the MCP config) provides `obsidian_search_notes`, `obsidian_read_note`, `obsidian_write_note`, `obsidian_patch_note`, `obsidian_manage_tags`, and related tools.
           - **Governance files**: The vault has four `AGENTS.md` files that define schemas, workflows, and naming conventions for each subsystem. These MUST be read before modifying any vault content:
             - `AGENTS.md` (root) — Vault architecture overview, three-subsystem model, integrated agent workflow
             - `Daily/AGENTS.md` — Daily note format specification (section ordering, task formatting, tags)
             - `LLM-Wiki/AGENTS.md` — Full wiki schema (page types, templates, naming conventions, research pipeline)
             - `Projects/AGENTS.md` — Project management system (kanban format, task-kanban relationship)
           - **Available Skills**: The sphoono/skills repository provides specialized skills for vault operations — `session-logger` (structured worklog entries), `daily-note-manager` (daily note creation), `wiki-index-regenerator` (wiki index rebuild), `frontmatter-linter` (frontmatter audits), `tag-sanitizer` (tag cleanup), and `vault-git-sync` (staged git commits). Invoke these via the `skill` tool when a task matches their purpose.

          ### Subsystems

          #### 1. Daily Work Log (Daily Notes + Calendar)
          - Daily notes serve as a running work log: what was done, discoveries made, decisions taken, blockers encountered.
          - The Calendar plugin provides navigation; daily notes must be created by the agent when a work session begins.
          - **Format**: Each daily note is a free-form markdown log with timestamps, observations, and links to related wiki pages or tasks (BE SURE TO KEEP THIS UPDATED).

          #### 2. Task / Todo Tracker (Tasks Plugin)
          - Tasks are tracked inline in daily notes (and optionally in project pages) using the Tasks plugin format:
            ```
            - [ ] #task Description 📅 2026-05-29
            - [x] #task Completed task ✅ 2026-05-29
            ```
          - Use `#task` tags for task tracking. The Tasks plugin queries, filters, and groups them across notes.
          - Track rate of completion, next actions, and dependencies via task metadata.

          #### 3. Research Knowledge Base (LLM Wiki)
          - The original Karpathy-style LLM Wiki: `raw/` (immutable sources) → `wiki/` (LLM-maintained concepts, entities, sources, comparisons) → `outputs/`.
          - Governed by the vault's `AGENTS.md` schema. Full ingest/query/lint workflows as defined there.
          - Use for deep research, architectural decision records, and accumulating durable knowledge across sessions.
          - **Research Skills**: Leverage the sphoono/skills research skill suite for wiki maintenance — `wiki-index-regenerator` to rebuild the master catalog, `frontmatter-linter` to audit frontmatter correctness and broken cross-references, `tag-sanitizer` to normalize tag usage, and `vault-git-sync` to commit wiki changes in organized batches. Load the relevant skill before performing wiki maintenance tasks.

          ### Agent Workflow

          This system is your primary workspace for session management. Follow this cycle on every task:

          1. **Session Start — Open the Day**
             - **Search** for today's daily note (`obsidian_search_notes` with today's date). If none exists, **create** one.
             - **Read** any open or overdue tasks (`obsidian_search_notes` with `#task` and today/overdue dates).
             - **Review** the wiki index (`wiki/index.md`) if the task involves research or prior context.
             - **Log** the session start: what you're setting out to do, the plan.

          2. **During Work — Keep the Log**
             - **Update** the daily note as work progresses: steps taken, dead ends, insights, decisions.
             - **Create/update tasks** to track subtasks, next actions, and completion status. Use `#task` with dates.
             - **Record findings** in the wiki when you discover something worth preserving (new concept, ADR, comparison).
              - Keep the work log in sync with your own internal todo tracking — if you would update the todowrite tool, also update the Obsidian daily note and tasks.
              - **Trigger session-logger after each stage**: Use the `session-logger` skill (loaded via the `skill` tool) after completing each logical development stage to automatically append a structured worklog entry to today's daily note. This captures project context, files changed, task status, and narrative description without manual copy-paste.

          3. **Session End — Close Out**
             - **Finalize** the daily note: summary of what was accomplished, what's pending, links to created wiki pages.
             - **Update task states**: mark done tasks as `[x]`, reschedule overdue items.
              - **Ensure wiki pages** are created for any durable knowledge generated during the session.
              - **Final session-logger entry**: Run the `session-logger` skill one final time to record the session summary, outcomes, and any follow-up tasks, ensuring the daily note is complete and up to date.

          4. **Before Any Non-Trivial Work — Consult First**
             - Read the vault's **root `AGENTS.md`** for the three-subsystem architecture overview.
             - Read the **relevant feature sub-directory's `AGENTS.md`** before modifying that subsystem:
                - `Daily/AGENTS.md` — before creating/restructuring daily notes or tasks
                - `LLM-Wiki/AGENTS.md` — before altering wiki pages, sources, or running research
                - `Projects/AGENTS.md` — before creating/restructuring project directories (kanban boards, issue write-ups, project structure)
             - Search the wiki (`wiki/index.md` + relevant concept pages) for prior context, existing decisions, and related research before implementing.
             - Search tasks for any blocked or related items.

           5. **Git Workflow — Branch, Commit, Push**
              - **Branch first**: If currently on `main` (or the default branch) of a repository, create a new branch before making any alterations. Name the branch based on the purpose of the work (e.g., `feat/add-monitoring`, `fix/netbird-oidc`, `refactor/k8s-structure`).
              - **Commit meaningfully**: After a meaningful unit of work has been completed (a logical change that is self-contained and verifiable), load and invoke the `git-commit` skill to commit your changes. Do not batch unrelated changes into a single commit.
              - **Push all commits**: After each commit (or batch of related commits), push the branch to the remote (`git push origin <branch-name>`). Do not leave committed work sitting unpushed on a local branch.
              - **Branch lifecycle**: Once the work is complete, the PR has been created (if applicable), and/or the user has confirmed, the branch can be merged. Clean up by deleting the remote branch after merge.

           ### Mandatory Confirmation Protocol

          **Always confirm plans with the user before enacting them.** This applies at every stage:

          - Before creating or modifying wiki pages outside the ingest workflow, describe what you plan to write and get approval.
          - Before modifying configuration files, present a clear before/after and ask for confirmation.
          - Before restructuring or archiving notes, show the plan and confirm.
          - When proposing a course of action, present 2–3 structured options and let the user decide.

          **Exception:** Trivial corrections (typos, formatting, obvious broken links) and the ingest workflow (raw/ → wiki/ pipeline as defined in the vault's AGENTS.md) may proceed without confirmation, but report what was done.

           ### Pre-Alteration Protocol for the Vault

           Before modifying any vault content, you MUST:

           1. **Load the relevant AGENTS.md** — Read the vault `AGENTS.md` for the subsystem you're about to modify. Each subsystem has its own schema:
              - `Daily/AGENTS.md` for daily notes and tasks
              - `LLM-Wiki/AGENTS.md` for wiki research pages
              - `Projects/AGENTS.md` for project directories (kanban boards, issue write-ups, project structure)
              - Root `AGENTS.md` for the overall architecture (read at session start or after context compaction)

           2. **Read the relevant sub-directory** — Explore the current state of the directory you're modifying:
              - For daily notes: list `Daily/` to see existing notes and templates
              - For wiki pages: list `LLM-Wiki/raw/<topic>/` and `LLM-Wiki/wiki/<type>/<topic>/` for existing content
              - For projects: each project lives in `Projects/<Name>/` with three files — `About.md` (project write-up), `Project.md` (kanban board), and `Issues/` (issue write-ups from problem solving). List `Projects/<Name>/` to see all files and check `Issues/README.md` for the issue index.

           3. **Understand conventions** — Check existing files for naming patterns, tag usage, frontmatter structure, and link formats before creating new ones.

           Do not re-read AGENTS.md files redundantly within the same session — read once at session start or after context compaction.
        '';
      };

      editors.context = {
        editor = ''
          # Editor Pair Programming Preferences: sphoono

          ## Development Philosophy
          - **Declarative First**: Prioritize Nix-native patterns and Infrastructure-as-Code principles. Maintain strict separation between configuration (Nix) and application logic.
          - **AI-Assisted Efficiency**: Leverage agentic abilities for boilerplate reduction, complex refactoring, and logical discovery.
          - **Terminal-Centric**: Maintain a tight feedback loop between the editor (Zed/Cursor) and the terminal environment (Fish/nh).

          ## Language & Ecosystem Specifics
          - **Nix**: Adhere to the established library patterns in `nix/lib.nix` and the modular structure in `nix/modules/`.
          - **Secrets**: Always use `sops-nix` for secret management; never hardcode or commit plain-text sensitive data.
          - **Git**: Use atomic commits and descriptive messages that explain the "why" of a change.

          ## Workflow Preferences
          - **Strategy-First**: For complex or multi-file changes, propose a technical strategy and obtain approval before implementation.
          - **Surgical Precision**: Focus exclusively on the requested task. Avoid unrelated refactoring or "cleanup" unless it directly supports the current objective.
          - **Verification**: Proactively suggest or write tests to verify logic changes.
        '';
      };
    };
  };
}
