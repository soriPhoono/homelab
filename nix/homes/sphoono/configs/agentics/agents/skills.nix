{
  pkgs,
  inputs,
  ...
}: {
  userapps.development.agentics.agents.skills =
    (with pkgs.skills; {
      # Skill Discovery
      find-skills = vercel-labs.skills.find-skills;

      # Core developer skills
      editorconfig = github.awesome-copilot.editorconfig;
      cli-mastery = github.awesome-copilot.cli-mastery;

      # Obsidian tooling
      obsidian-markdown = kepano.obsidian-skills.obsidian-markdown;
      obsidian-cli = kepano.obsidian-skills.obsidian-cli;
      obsidian-bases = kepano.obsidian-skills.obsidian-bases;
      json-canvas = kepano.obsidian-skills.json-canvas;
      defuddle = kepano.obsidian-skills.defuddle;
      obsidian = bitbonsai.mcpvault.obsidian;

      # Git Workflows
      conventional-commit = github.awesome-copilot.git-commit;
      git-flow-branch-creator = github.awesome-copilot.git-flow-branch-creator;

      # Documentation & Communication
      create-readme = github.awesome-copilot.create-readme;
      documentation-writer = github.awesome-copilot.documentation-writer;
      create-llms = github.awesome-copilot.create-llms;
      update-llms = github.awesome-copilot.update-llms;
      write-coding-standards-from-file = github.awesome-copilot.write-coding-standards-from-file;
      context-map = github.awesome-copilot.context-map;
      generate-custom-instructions-from-codebase =
        github.awesome-copilot.generate-custom-instructions-from-codebase;
      what-context-needed = github.awesome-copilot.what-context-needed;

      # Security
      security-review = github.awesome-copilot.security-review;
      secret-scanning = github.awesome-copilot.secret-scanning;
      threat-model-analyst = github.awesome-copilot.threat-model-analyst;
      security-best-practices = openai.skills.security-best-practices;
      security-threat-model = openai.skills.security-threat-model;
      security-ownership-map = openai.skills.security-ownership-map;
      gdpr-compliant = github.awesome-copilot.gdpr-compliant;

      # Architecture & Planning
      architecture-blueprint-generator = github.awesome-copilot.architecture-blueprint-generator;
      technology-stack-blueprint-generator = github.awesome-copilot.technology-stack-blueprint-generator;
      folder-structure-blueprint-generator = github.awesome-copilot.folder-structure-blueprint-generator;
      create-specification = github.awesome-copilot.create-specification;
      create-implementation-plan = github.awesome-copilot.create-implementation-plan;
      create-technical-spike = github.awesome-copilot.create-technical-spike;
      create-architectural-decision-record = github.awesome-copilot.create-architectural-decision-record;
      breakdown-feature-implementation = github.awesome-copilot.breakdown-feature-implementation;
      breakdown-epic-arch = github.awesome-copilot.breakdown-epic-arch;
      refactor = github.awesome-copilot.refactor;
      refactor-plan = github.awesome-copilot.refactor-plan;
      review-and-refactor = github.awesome-copilot.review-and-refactor;

      # Browser Automation (Playwright — Firefox-first)
      playwright = openai.skills.playwright;
      playwright-interactive = openai.skills.playwright-interactive;
      webapp-testing = github.awesome-copilot.webapp-testing;
      web-design-reviewer = github.awesome-copilot.web-design-reviewer;

      # Developer Experience & Workflow
      github-issues = github.awesome-copilot.github-issues;
      dependabot = github.awesome-copilot.dependabot;

      # MCP Server Development
      python-mcp-server-generator = github.awesome-copilot.python-mcp-server-generator;
      typescript-mcp-server-generator = github.awesome-copilot.typescript-mcp-server-generator;
      go-mcp-server-generator = github.awesome-copilot.go-mcp-server-generator;
      java-mcp-server-generator = github.awesome-copilot.java-mcp-server-generator;
      rust-mcp-server-generator = github.awesome-copilot.rust-mcp-server-generator;
      mcp-cli = github.awesome-copilot.mcp-cli;
      mcp-integration = anthropics.claude-code.mcp-integration;
      build-mcp-server = anthropics.claude-plugins-official.build-mcp-server;
      build-mcp-app = anthropics.claude-plugins-official.build-mcp-app;
      mcp-builder = anthropics.skills.mcp-builder;

      # Obsidian Wiki (ar9av/obsidian-wiki) — LLM Wiki pattern framework
      wiki-setup = ar9av.obsidian-wiki.wiki-setup;
      wiki-ingest = ar9av.obsidian-wiki.wiki-ingest;
      wiki-history-ingest = ar9av.obsidian-wiki.wiki-history-ingest;
      claude-history-ingest = ar9av.obsidian-wiki.claude-history-ingest;
      codex-history-ingest = ar9av.obsidian-wiki.codex-history-ingest;
      hermes-history-ingest = ar9av.obsidian-wiki.hermes-history-ingest;
      openclaw-history-ingest = ar9av.obsidian-wiki.openclaw-history-ingest;
      copilot-history-ingest = ar9av.obsidian-wiki.copilot-history-ingest;
      pi-history-ingest = ar9av.obsidian-wiki.pi-history-ingest;
      data-ingest = ar9av.obsidian-wiki.data-ingest;
      ingest-url = ar9av.obsidian-wiki.ingest-url;
      obsidian-wiki-ingest = ar9av.obsidian-wiki.obsidian-wiki-ingest;
      wiki-status = ar9av.obsidian-wiki.wiki-status;
      wiki-rebuild = ar9av.obsidian-wiki.wiki-rebuild;
      wiki-query = ar9av.obsidian-wiki.wiki-query;
      wiki-lint = ar9av.obsidian-wiki.wiki-lint;
      cross-linker = ar9av.obsidian-wiki.cross-linker;
      tag-taxonomy = ar9av.obsidian-wiki.tag-taxonomy;
      llm-wiki = ar9av.obsidian-wiki.llm-wiki;
      wiki-update = ar9av.obsidian-wiki.wiki-update;
      wiki-export = ar9av.obsidian-wiki.wiki-export;
      wiki-capture = ar9av.obsidian-wiki.wiki-capture;
      wiki-quick-chat-capture = ar9av.obsidian-wiki.wiki-quick-chat-capture;
      wiki-research = ar9av.obsidian-wiki.wiki-research;
      wiki-dashboard = ar9av.obsidian-wiki.wiki-dashboard;
      wiki-synthesize = ar9av.obsidian-wiki.wiki-synthesize;
      wiki-agent = ar9av.obsidian-wiki.wiki-agent;
      wiki-context-pack = ar9av.obsidian-wiki.wiki-context-pack;
      wiki-dedup = ar9av.obsidian-wiki.wiki-dedup;
      wiki-digest = ar9av.obsidian-wiki.wiki-digest;
      wiki-import = ar9av.obsidian-wiki.wiki-import;
      wiki-stage-commit = ar9av.obsidian-wiki.wiki-stage-commit;
      wiki-switch = ar9av.obsidian-wiki.wiki-switch;
      memory-bridge = ar9av.obsidian-wiki.memory-bridge;
      daily-update = ar9av.obsidian-wiki.daily-update;
      impl-validator = ar9av.obsidian-wiki.impl-validator;
      graph-colorize = ar9av.obsidian-wiki.graph-colorize;
      skill-creator = ar9av.obsidian-wiki.skill-creator;
    })
    // {
      # Custom Obsidian vault skills from github:soriPhoono/skills
      # These are { src, subpath } specs — auto-coerced to derivations by the
      # types.coercedTo in the skills module option.
      # Session management
      obsidian-session-logger = {
        src = inputs.skills;
        subpath = "skills/obsidian/session-logger";
      };
      obsidian-session-closeout = {
        src = inputs.skills;
        subpath = "skills/obsidian/session-closeout";
      };
      obsidian-daily-note-manager = {
        src = inputs.skills;
        subpath = "skills/obsidian/daily-note-manager";
      };
      obsidian-frontmatter-linter = {
        src = inputs.skills;
        subpath = "skills/obsidian/frontmatter-linter";
      };
      obsidian-tag-sanitizer = {
        src = inputs.skills;
        subpath = "skills/obsidian/tag-sanitizer";
      };
      obsidian-wiki-index-regenerator = {
        src = inputs.skills;
        subpath = "skills/obsidian/wiki-index-regenerator";
      };
      obsidian-vault-git-sync = {
        src = inputs.skills;
        subpath = "skills/obsidian/vault-git-sync";
      };

      # Research skills — LLM Wiki pipeline
      obsidian-deep-research = {
        src = inputs.skills;
        subpath = "skills/obsidian/deep-research";
      };
      obsidian-quick-research = {
        src = inputs.skills;
        subpath = "skills/obsidian/quick-research";
      };
      obsidian-source-ingest = {
        src = inputs.skills;
        subpath = "skills/obsidian/source-ingest";
      };

      # Source organization
      obsidian-organize-raw-sources = {
        src = inputs.skills;
        subpath = "skills/obsidian/organize-raw-sources";
      };

      # Project management
      obsidian-create-project = {
        src = inputs.skills;
        subpath = "skills/obsidian/create-project";
      };
      obsidian-task-issue-auditor = {
        src = inputs.skills;
        subpath = "skills/obsidian/task-issue-auditor";
      };
    };
}
