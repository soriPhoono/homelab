{pkgs, ...}: let
  src = pkgs.fetchFromGitHub {
    owner = "ankitmundada";
    repo = "awesome-opencode-subagents";
    rev = "e5161766863effac2564d11b872e0ae06bee9aa7";
    sha256 = "1z7602pbfj6qv6m24ay4csb407yngh95yqn7znzbbkbp8dsmcims";
  };

  agent = category: name: "${src}/categories/${category}/${name}.md";
in {
  userapps.development.agentics.agents.subagents.registry = {
    # 04-quality-security
    accessibility-tester = agent "04-quality-security" "accessibility-tester";
    ad-security-reviewer = agent "04-quality-security" "ad-security-reviewer";
    architect-reviewer = agent "04-quality-security" "architect-reviewer";
    chaos-engineer = agent "04-quality-security" "chaos-engineer";
    code-reviewer = agent "04-quality-security" "code-reviewer";
    compliance-auditor = agent "04-quality-security" "compliance-auditor";
    debugger = agent "04-quality-security" "debugger";
    error-detective = agent "04-quality-security" "error-detective";
    penetration-tester = agent "04-quality-security" "penetration-tester";
    performance-engineer = agent "04-quality-security" "performance-engineer";
    powershell-security-hardening = agent "04-quality-security" "powershell-security-hardening";
    qa-expert = agent "04-quality-security" "qa-expert";
    security-auditor = agent "04-quality-security" "security-auditor";
    test-automator = agent "04-quality-security" "test-automator";

    # 06-developer-experience
    build-engineer = agent "06-developer-experience" "build-engineer";
    cli-developer = agent "06-developer-experience" "cli-developer";
    dependency-manager = agent "06-developer-experience" "dependency-manager";
    documentation-engineer = agent "06-developer-experience" "documentation-engineer";
    dx-optimizer = agent "06-developer-experience" "dx-optimizer";
    git-workflow-manager = agent "06-developer-experience" "git-workflow-manager";
    legacy-modernizer = agent "06-developer-experience" "legacy-modernizer";
    mcp-developer = agent "06-developer-experience" "mcp-developer";
    powershell-module-architect = agent "06-developer-experience" "powershell-module-architect";
    powershell-ui-architect = agent "06-developer-experience" "powershell-ui-architect";
    refactoring-specialist = agent "06-developer-experience" "refactoring-specialist";
    slack-expert = agent "06-developer-experience" "slack-expert";
    tooling-engineer = agent "06-developer-experience" "tooling-engineer";

    # 09-meta-orchestration
    context-manager = agent "09-meta-orchestration" "context-manager";
    error-coordinator = agent "09-meta-orchestration" "error-coordinator";
    it-ops-orchestrator = agent "09-meta-orchestration" "it-ops-orchestrator";
    knowledge-synthesizer = agent "09-meta-orchestration" "knowledge-synthesizer";
    multi-agent-coordinator = agent "09-meta-orchestration" "multi-agent-coordinator";
    performance-monitor = agent "09-meta-orchestration" "performance-monitor";
    task-distributor = agent "09-meta-orchestration" "task-distributor";
    workflow-orchestrator = agent "09-meta-orchestration" "workflow-orchestrator";

    # 10-research-analysis
    competitive-analyst = agent "10-research-analysis" "competitive-analyst";
    data-researcher = agent "10-research-analysis" "data-researcher";
    market-researcher = agent "10-research-analysis" "market-researcher";
    research-analyst = agent "10-research-analysis" "research-analyst";
    search-specialist = agent "10-research-analysis" "search-specialist";
    trend-analyst = agent "10-research-analysis" "trend-analyst";
  };
}
