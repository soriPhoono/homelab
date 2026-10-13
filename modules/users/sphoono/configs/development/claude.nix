{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    nix-skills.url = "github:sudosubin/nix-skills";
    mem0 = {
      url = "github:mem0ai/mem0/v2.2.1";
      flake = false;
    };
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
        kwp = inputs.knowledge-work-plugins;
        # small-business skills read ../../shared/*.md (and ../../../shared/
        # from nested files) relative to their own directory, which breaks
        # once each skill is linked on its own. Point those at the store.
        smbSkill =
          name:
          pkgs.runCommand name { } ''
            cp -r ${kwp}/small-business/skills/${name} $out
            chmod -R u+w $out
            find $out -type f -name '*.md' -exec sed -E -i \
              -e 's|(\.\./)+shared/|${kwp}/small-business/shared/|g' \
              -e 's|(\.\./)+ad-manager/|${kwp}/small-business/skills/ad-manager/|g' {} +
          '';
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
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
        programs.claude-code = {
          enable = true;
          mcpServers = {
            rea.command = lib.getExe rea-mcp;
            # NixOS, Home Manager and nixpkgs option and package lookup over
            # stdio. Referenced by store path, so it is not on the user's
            # PATH.
            nixos.command = lib.getExe pkgs.mcp-nixos;
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
            ${builtins.readFile ../../assets/documents/user.md}

            ${builtins.readFile ../../assets/documents/claude/AGENTS.md}
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
            # Hand outside research to Antigravity, and implement the plans
            # it hands back
            antigravity-research = ../../assets/skills/antigravity-research;
            plan-watch = ../../assets/skills/plan-watch;
            # Build n8n workflows through the n8n MCP server
            inherit (pkgs.agent-skills.github.czlonkowski.n8n-skills)
              n8n-mcp-tools-expert
              n8n-workflow-patterns
              n8n-expression-syntax
              n8n-validation-expert
              n8n-code-javascript
              ;
            # SDLC: pipelines, release readiness, ADRs, observability,
            # hardening, interface design and migrations. superpowers
            # already covers TDD, debugging, planning and review.
            inherit (pkgs.agent-skills.github.addyosmani.agent-skills)
              ci-cd-and-automation
              shipping-and-launch
              documentation-and-adrs
              observability-and-instrumentation
              security-and-hardening
              api-and-interface-design
              deprecation-and-migration
              ;
            # Finance: variance, reconciliation, statements and close
            variance-analysis = "${kwp}/finance/skills/variance-analysis";
            reconciliation = "${kwp}/finance/skills/reconciliation";
            financial-statements = "${kwp}/finance/skills/financial-statements";
            close-management = "${kwp}/finance/skills/close-management";
            journal-entry-prep = "${kwp}/finance/skills/journal-entry-prep";
            # Data analysis
            sql-queries = "${kwp}/data/skills/sql-queries";
            statistical-analysis = "${kwp}/data/skills/statistical-analysis";
            data-visualization = "${kwp}/data/skills/data-visualization";
            validate-data = "${kwp}/data/skills/validate-data";
            # Operations
            runbook = "${kwp}/operations/skills/runbook";
            capacity-plan = "${kwp}/operations/skills/capacity-plan";
            process-doc = "${kwp}/operations/skills/process-doc";
            risk-assessment = "${kwp}/operations/skills/risk-assessment";
            process-optimization = "${kwp}/operations/skills/process-optimization";
            # Legal: contract and NDA review, risk and compliance checks.
            # Drafts for a lawyer's review, not legal advice.
            review-contract = "${kwp}/legal/skills/review-contract";
            triage-nda = "${kwp}/legal/skills/triage-nda";
            legal-risk-assessment = "${kwp}/legal/skills/legal-risk-assessment";
            compliance-check = "${kwp}/legal/skills/compliance-check";
            # Dropshipping books and growth, over the QuickBooks and Shopify
            # connectors
            month-end-prep = smbSkill "month-end-prep";
            close-month = smbSkill "close-month";
            cash-flow-snapshot = smbSkill "cash-flow-snapshot";
            business-pulse = smbSkill "business-pulse";
            report-builder = smbSkill "report-builder";
            growth-pulse = smbSkill "growth-pulse";
            # Reverse engineering; drives the REA MCP tools
            reverse-engineer-anything = "${inputs.rea}/.agents/skills/reverse-engineer-anything";
            # Keep the Notion project wiki and tasks current
            inherit (pkgs.agent-skills.github.makenotion.claude-code-notion-plugin)
              knowledge-capture
              spec-to-implementation
              ;
          };
        };
      };
  };
}
