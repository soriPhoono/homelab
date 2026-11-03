{ den, inputs, ... }: {
  flake-file.inputs.nix-skills.url = "github:sudosubin/nix-skills";

  den.aspects.sphoono.development.opencode = {
    includes = [
      den.aspects.sphoono.development.honcho
    ];
    homeManager =
      {
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
        tailnetDomain = "xerus-augmented.ts.net";
        gateway = "https://sphoono-vps-9router.${tailnetDomain}/v1";

        syncModels = pkgs.writeShellApplication {
          name = "opencode-sync-models";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
            pkgs.sqlite
          ];
          text = ''
            dest="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.jsonc"
            db="''${XDG_DATA_HOME:-$HOME/.local/share}/opencode/opencode.db"
            mkdir -p "$(dirname "$dest")"
            tmp="$(mktemp)"
            trap 'rm -f "$tmp" "$tmp.out"' EXIT

            # Not an error before the first `/connect`; there is nothing to retry.
            key=""
            if [ -f "$db" ]; then
              key="$(sqlite3 -readonly "$db" \
                "select json_extract(value, '$.key') from credential
                 where integration_id = '9router' order by time_updated desc limit 1" || true)"
            fi
            if [ -z "$key" ]; then
              echo "no 9router credential yet; run /connect in OpenCode, then opencode-sync-models" >&2
              exit 0
            fi

            # The tailnet may still be coming up at login.
            for _ in $(seq 1 30); do
              if curl -fsS --max-time 5 -H "Authorization: Bearer $key" \
                -o "$tmp" ${gateway}/models; then
                break
              fi
              sleep 2
            done
            [ -s "$tmp" ] || { echo "gateway did not answer; keeping the old list" >&2; exit 1; }

            # OpenCode 2 model schema: capabilities and limit.
            jq --arg url "${gateway}" '
              { providers: { "9router": {
                settings: { baseURL: $url },
                models: (
                  .data
                  | map({ key: .id, value: {
                      name: .id,
                      capabilities: {
                        tools: (.capabilities.tools // false),
                        input: (
                          ["text"]
                          + (if .capabilities.vision then ["image"] else [] end)
                          + (if .capabilities.pdf then ["pdf"] else [] end)
                          + (if .capabilities.audioInput then ["audio"] else [] end)
                          + (if .capabilities.videoInput then ["video"] else [] end)
                        ),
                        output: (
                          ["text"]
                          + (if .capabilities.imageOutput then ["image"] else [] end)
                          + (if .capabilities.audioOutput then ["audio"] else [] end)
                        ),
                        reasoning: { supported: (.capabilities.reasoning // false) }
                      },
                      limit: {
                        context: (.context_length // 128000),
                        output: (.max_completion_tokens // 8192)
                      }
                    } })
                  | from_entries
                ) } } }
            ' "$tmp" > "$tmp.out"

            mv "$tmp.out" "$dest"
            echo "wrote $(jq '.providers."9router".models | length' "$dest") models to $dest"
          '';
        };
      in
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];

        home.packages = [ syncModels ];

        # Run `opencode-sync-models` after changing providers in the dashboard.
        systemd.user.services.opencode-9router-models = {
          Unit.Description = "List 9router models for OpenCode";
          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe syncModels;
            # Retry while the tailnet comes up.
            Restart = "on-failure";
            RestartSec = 30;
          };
          Install.WantedBy = [ "default.target" ];
        };

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
            package =
              let
                agent = pkgs.opencode;
              in
              pkgs.symlinkJoin {
                inherit (agent) pname;
                inherit (agent) version;
                name = "${agent.name}"; # TODO: name this properly after implementation

                paths = [ agent ];
                buildInputs = [ pkgs.makeWrapper ];
                postBuild = ''
                  for bin in $out/bin/*; do
                    if [ -f "$bin" ] && [ -x "$bin" ]; then
                      wrapProgram "$bin" \
                        --prefix PATH : ${
                          lib.makeBinPath [
                            pkgs.nodejs
                            pkgs.python3
                          ]
                        } \
                        --run 'export OPENCODE_DISABLE_CLAUDE_CODE=1'
                    fi
                  done
                '';
              };
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
                  notion = {
                    type = "remote";
                    url = "https://mcp.notion.com/mcp";
                  };
                };
              };
            };
            context = ''
              ${builtins.readFile ../../../assets/documents/user.md}

              ${builtins.readFile ../../../assets/documents/agent-roles/coding.md}

              ${builtins.readFile ../../../assets/documents/agent-roles/nix-infrastructure.md}

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
            }
            // awesomeSkills;
          };
      };
  };
}
