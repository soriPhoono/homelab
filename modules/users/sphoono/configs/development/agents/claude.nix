{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    nix-skills.url = "github:sudosubin/nix-skills";
    # nix-skills has not yet indexed these two repos (tracked in its
    # sources.json but no skill data generated), so their skills are
    # taken directly instead of through pkgs.agent-skills.
    awesome-copilot = {
      url = "github:github/awesome-copilot/d6131471b85fbb4799e64175ebc42c9309ecc28a";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills/d81f3a183412e71a5b1e84ca21bc1a35eea03a60";
      flake = false;
    };
    claude-plugins-official = {
      url = "github:anthropics/claude-plugins-official/d182ca456ca09d31d139f7d3818d1d333b103cce";
      flake = false;
    };
    # Pinned to the revision claude-plugins-official lists for it.
    superpowers = {
      url = "github:obra/superpowers/5bf4e78011075bcfc0dc295f0724994cd123ee71";
      flake = false;
    };
    # rea-agents-6.4.0. The skill must match the MCP server version pinned
    # below; nix-skills indexes only 3.2.1.
    rea = {
      url = "github:morluto/rea/a56f7bb668ab23fec8d33f7af353ac7ed2fe1895";
      flake = false;
    };
    # Individual skills only. The plugins' own .mcp.json files would register
    # Snowflake, Databricks, Slack, Atlassian and others, so none of them is
    # installed as a plugin.
    knowledge-work-plugins = {
      url = "github:anthropics/knowledge-work-plugins/02ffa99ff00ce4d3046ccebabb8357cb39f3ab06";
      flake = false;
    };
  };
  den.aspects.sphoono.development.claude = {
    # claude-code is unfree.
    includes = [ (den.batteries.unfree [ "claude-code" ]) ];
    homeManager =
      { config, pkgs, ... }:
      let
        # Every skill of seb1n/awesome-ai-agent-skills. Merged last, so it
        # wins on a name clash, and the installed skills these replace
        # (ci-cd-and-automation, observability-and-instrumentation,
        # api-and-interface-design, sql-queries, data-visualization,
        # financial-statements, review-contract) are no longer linked, and
        # so is antigravity-research. note-taking, project-management and
        # task-automation are left out: the Obsidian and n8n skills target
        # those jobs.
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
        # small-business skills read ../../shared/*.md (and ../../../shared/
        # from nested files) relative to their own directory, which breaks
        # once each skill is linked on its own. Point those at the store.
        # Node, the JDK and Ghidra exist only inside this launcher, so
        # claude's MCP server resolves them and the user's shell does not.
        rea-mcp = pkgs.writeShellApplication {
          name = "rea-mcp";
          runtimeInputs = [
            pkgs.nodejs_22
            pkgs.jdk21
          ];
          runtimeEnv = {
            GHIDRA_INSTALL_DIR = "${pkgs.ghidra}/lib/ghidra";
            JAVA_HOME = "${pkgs.jdk21}";
          };
          text = ''
            exec npx -y rea-agents@6.4.0 mcp "$@"
          '';
        };
      in
      {
        sops.secrets."api/mem0-api-key" = { };
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
        programs.claude-code = {
          enable = true;
          mcpServers = {
            rea.command = lib.getExe rea-mcp;
            # The nixos lookup server is dropped: nixpkgs marks its
            # dependency fastmcp-slim broken (2026-10-19), and Claude Code is
            # being retired. OpenCode carries its own entry.
          };
          package =
            let
              agent = pkgs.claude-code;
            in
            pkgs.symlinkJoin {
              inherit (agent) pname;
              inherit (agent) version;
              name = "${agent.name}-with-python";

              paths = [ agent ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]} \
                      --run 'export MEM0_API_KEY="$(cat ${config.sops.secrets."api/mem0-api-key".path})"'
                  fi
                done
              '';
            };
          settings = {
            # Opus plans, Sonnet executes.
            model = "opusplan";
            effortLevel = "medium";
            env = {
              # Opt the mem0 plugin's hooks, MCP server and flush worker out
              # of usage telemetry.
              MEM0_TELEMETRY = "false";
              # Subagents default to Sonnet; frontmatter or a per-call model
              # still overrides this.
              CLAUDE_CODE_SUBAGENT_MODEL = "sonnet";
            };
          };
          context = ''
            ${builtins.readFile ../../../assets/documents/user.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/coding.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/nix-infrastructure.md}

            ${builtins.readFile ../../../assets/documents/agents/claude.md}
          '';
          marketplaces = {
            inherit (inputs) mem0;
          };
          plugins = {
            # The marketplace manifest points the "mem0" plugin at this
            # subdirectory of the repo, not the repo root.
            mem0 = "${inputs.mem0}/integrations/claude-code-plugin";
            # Baseline: keep AGENTS.md/CLAUDE.md current, and turn repeated
            # corrections into hooks (hookify's hooks run on the python3
            # the wrapper above puts on PATH).
            claude-md-management = "${inputs.claude-plugins-official}/plugins/claude-md-management";
            hookify = "${inputs.claude-plugins-official}/plugins/hookify";
            # Development: guided feature workflow and specialised PR review
            # agents.
            feature-dev = "${inputs.claude-plugins-official}/plugins/feature-dev";
            pr-review-toolkit = "${inputs.claude-plugins-official}/plugins/pr-review-toolkit";
            # Brainstorming, plan-driven subagent development, systematic
            # debugging and red/green TDD.
            superpowers = "${inputs.superpowers}";
          };
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
}
