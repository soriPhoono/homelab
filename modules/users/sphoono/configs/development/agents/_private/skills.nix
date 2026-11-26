# Skills shared by every coding agent (opencode, claude-code). Evaluates to
# an attrset of skill name to skill directory, the shape both Home Manager
# modules take for their `skills` option.
{
  inputs,
  lib,
  pkgs,
}:
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
// awesomeSkills
