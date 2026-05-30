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


          ## Daily Work Log, Planner & Wiki System

          This is an integrated Obsidian-based system spanning three complementary subsystems: a daily work log (Daily Notes + Calendar), a task/todo tracker (Tasks plugin), and a research knowledge base (LLM Wiki). All live in the same vault and are accessed via the `obsidian` MCP server.

          ### Vault Location & Tooling

          - **Vault root**: `~/Nextcloud/Notes/` — an Obsidian vault synchronized via Nextcloud.
          - **Access**: The Obsidian MCP server (`obsidian` in the MCP config) provides `obsidian_search_notes`, `obsidian_read_note`, `obsidian_write_note`, `obsidian_patch_note`, `obsidian_manage_tags`, and related tools.
          - **Wiki AGENTS.md**: The vault's `AGENTS.md` defines the research knowledge base schema (raw/ → wiki/ pipeline, page types, naming conventions). Load it into context before altering the wiki portion of the vault.

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

          3. **Session End — Close Out**
             - **Finalize** the daily note: summary of what was accomplished, what's pending, links to created wiki pages.
             - **Update task states**: mark done tasks as `[x]`, reschedule overdue items.
             - **Ensure wiki pages** are created for any durable knowledge generated during the session.

          4. **Before Any Non-Trivial Work — Consult First**
             - Search the wiki for prior context, existing decisions, and related research before implementing.
             - Search tasks for any blocked or related items.

          ### Mandatory Confirmation Protocol

          **Always confirm plans with the user before enacting them.** This applies at every stage:

          - Before creating or modifying wiki pages outside the ingest workflow, describe what you plan to write and get approval.
          - Before modifying configuration files, present a clear before/after and ask for confirmation.
          - Before restructuring or archiving notes, show the plan and confirm.
          - When proposing a course of action, present 2–3 structured options and let the user decide.

          **Exception:** Trivial corrections (typos, formatting, obvious broken links) and the ingest workflow (raw/ → wiki/ pipeline as defined in the vault's AGENTS.md) may proceed without confirmation, but report what was done.

          ### Pre-Alteration Protocol for the Wiki

          When altering the vault's AGENTS.md (the schema file, not the daily/task system):
          - Ensure it is fully loaded into context first.
          - Read it once at session start or after context compaction — do not re-read redundantly.
          - This applies only to the wiki schema; daily notes and tasks are free-form and do not require schema loading before modification.
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
