{ den, inputs, ... }: {
  flake-file.inputs.nix-skills.url = "github:sudosubin/nix-skills";

  den.aspects.sphoono.development.opencode = {
    includes = [
      den.aspects.sphoono.development.honcho
      den.aspects.sphoono.development.ninerouter
    ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # OpenCode reaches the 9router gateway on sphoono-vps over the tailnet
        # through docktail. It does not discover models from an
        # OpenAI-compatible endpoint, so a oneshot lists the gateway's
        # `/v1/models` into `opencode.jsonc` beside the managed
        # `opencode.json`, which OpenCode merges. The API key is entered with
        # `/connect` in OpenCode, which keeps it in the `credential` table of
        # its database. The oneshot only reads it from there to list models;
        # nothing secret is written to a file.
        gateway = config.development.ninerouter.url;
      in
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];

        programs.opencode =
          let
            awesomeSkills = lib.mergeAttrsList (
              lib.mapAttrsToList
                (
                  category: names: lib.genAttrs names (name: "${inputs.awesome-ai-agent-skills}/${category}/${name}")
                )
                {
                  agent-engineering = [
                    "agent-evaluation"
                    "agent-observability"
                    "human-in-the-loop"
                    "mcp-server-building"
                    "multi-agent-orchestration"
                    "tool-schema-design"
                  ];
                  agent-security = [
                    "agent-red-teaming"
                    "prompt-injection-defense"
                    "skill-supply-chain-audit"
                  ];
                  ai-ml-operations = [
                    "data-labeling"
                    "hyperparameter-tuning"
                    "ml-pipeline-creation"
                    "model-deployment"
                    "model-training"
                  ];
                  api-and-integration = [
                    "api-design"
                    "api-integration"
                    "graphql-api-design"
                    "oauth-2-0-setup"
                    "webhook-setup"
                  ];
                  code-and-development = [
                    "code-documentation"
                    "code-review"
                    "debugging"
                    "refactoring"
                    "testing"
                    "version-control"
                  ];
                  communication = [
                    "chatbot-conversation-design"
                    "email-drafting"
                    "meeting-transcription"
                    "presentation-creation"
                    "report-generation"
                  ];
                  context-engineering = [
                    "context-compression"
                    "context-injection"
                    "context-optimization"
                    "context-ranking"
                    "context-retrieval"
                  ];
                  customer-success = [
                    "churn-analysis"
                    "customer-feedback-analysis"
                    "knowledge-base-article-writing"
                    "onboarding-playbook-creation"
                    "ticket-triage"
                  ];
                  data-and-analytics = [
                    "data-analysis"
                    "data-cleaning"
                    "data-visualization"
                    "exploratory-data-analysis"
                    "sql-query-generation"
                  ];
                  database = [
                    "database-backup"
                    "database-migration"
                    "database-schema-design"
                    "database-seeding"
                    "query-optimization"
                  ];
                  design-and-ui-ux = [
                    "accessibility-testing"
                    "frontend-design"
                    "logo-design"
                    "user-flow-mapping"
                    "wireframing"
                  ];
                  devops-and-infrastructure = [
                    "ci-cd"
                    "cloud-monitoring"
                    "docker-compose-setup"
                    "infrastructure-as-code"
                    "kubernetes-deployment"
                  ];
                  documents-and-files = [
                    "pdf-processing"
                    "spreadsheet-analysis"
                  ];
                  finance-and-accounting = [
                    "budget-planning"
                    "expense-categorization"
                    "financial-modeling"
                    "financial-report-generation"
                    "invoice-processing"
                  ];
                  legal-and-compliance = [
                    "compliance-checklist-generation"
                    "contract-review"
                    "eu-ai-act-readiness"
                    "license-analysis"
                    "privacy-policy-drafting"
                    "terms-of-service-generation"
                  ];
                  marketing-and-seo = [
                    "analytics-reporting"
                    "content-strategy"
                    "keyword-research"
                    "seo-optimization"
                    "social-media-posting"
                  ];
                  productivity-and-workflow = [
                    "file-organization"
                    "meeting-scheduler"
                  ];
                  research-and-knowledge = [
                    "deep-research"
                    "fact-checking"
                    "knowledge-graph-creation"
                    "literature-review"
                    "summarization"
                  ];
                  sales = [
                    "competitive-battlecard-creation"
                    "crm-data-enrichment"
                    "lead-scoring"
                    "proposal-generation"
                    "sales-email-sequences"
                  ];
                  security = [
                    "dependency-scanning"
                    "dynamic-application-security-testing"
                    "security-audit"
                    "static-application-security-testing"
                    "threat-modeling"
                  ];
                  writing-and-content = [
                    "blog-post-writing"
                    "copywriting"
                    "proofreading"
                    "technical-writing"
                    "translation"
                  ];
                }
            );
          in
          {
            enable = true;
            package = import ./_private/wrap-opencode.nix { inherit lib pkgs; } pkgs.opencode;
            settings = {
              plugin = [ "@honcho-ai/opencode-honcho" ];
              providers."9router" = {
                name = "9router";
                package = "aisdk:@ai-sdk/openai-compatible";
                settings.baseURL = gateway;
              };
              mcp = {
                servers = {
                  n8n = {
                    type = "remote";
                    url = "https://agents.cryptic-coders.net/mcp-server/http";
                  };
                };
              };
            };
            context = ''
              ${builtins.readFile ../../../assets/documents/user.md}

              ${builtins.readFile ../../../assets/documents/agents/opencode.md}
            '';
            skills = {
              # Writing
              stop-slop = pkgs.agent-skills.github.hardikpandya.stop-slop.stop-slop;
              # Thinking
              grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
              grill-me = "${inputs.mattpocock-skills}/skills/productivity/grill-me";
              grill-with-docs = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
              # Create agentic integrations
              create-agentsmd = "${inputs.awesome-copilot}/skills/create-agentsmd";
              create-readme = "${inputs.awesome-copilot}/skills/create-readme";
              # Work with git repos
              git-commit = "${inputs.awesome-copilot}/skills/git-commit";
              # Work with the Obsidian vault: markdown, bases, canvas and CLI
              inherit (pkgs.agent-skills.github.obsidianmd.obsidian-skills)
                defuddle
                json-canvas
                knap
                obsidian-bases
                obsidian-cli
                obsidian-headless
                obsidian-markdown
                ;
            }
            // awesomeSkills;
          };
      };
  };

  # OpenCode Desktop, for hosts with a desktop. It reads the same
  # ~/.config/opencode as the CLI, so it shares the settings, providers, MCP
  # servers, skills and plugin above.
  den.aspects.sphoono.development.opencode.desktop.homeManager =
    { lib, pkgs, ... }:
    let
      desktop = import ./_private/wrap-opencode.nix { inherit lib pkgs; } pkgs.opencode-desktop;
      inherit (import ../../desktop/wm/hypr/_private/lib.nix { inherit lib; }) bind exec;
    in
    {
      home.packages = [ desktop ];

      # Declared here rather than with the global binds, so the key exists
      # only where the app does. Inert on a home without Hyprland.
      wayland.windowManager.hyprland.settings.bind = [
        (bind "SUPER + C" (exec "${lib.getExe pkgs.uwsm} app -- ${lib.getExe desktop}"))
      ];
    };
}
