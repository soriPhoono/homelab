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


          ## LLM Wiki (Research Knowledge Base)
          - **Location**: `~/GoogleDrive/Documents/LLM-Wiki` — an Obsidian vault based on Karpathy's LLM Wiki design.
          - **Purpose**: Serves as the primary research and knowledge repository for software development tasks. Contains design notes, architecture decisions, technical research, and project-specific documentation accumulated across sessions.
          - **Tooling**: The Obsidian MCP server (configured as `obsidian` in the MCP configuration) provides full read/write access to the vault. Use `obsidian_search_notes`, `obsidian_read_note`, `obsidian_write_note`, and related tools to interact with the wiki.
          - **Workflow Requirement**: Before beginning any non-trivial software development task, **consult the LLM Wiki** for relevant prior research, design decisions, or existing context. After completing significant research or making architectural decisions, **record findings** in the wiki to build durable institutional knowledge across agent sessions.
          - **Pre-Alteration Protocol**: Ensure the wiki's `agents.md` (operational best practices, agentic principles, and established conventions) is fully loaded into context before making alterations. Read it once at the start of a session or after context compaction — do not re-read redundantly if it is already in context.
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
