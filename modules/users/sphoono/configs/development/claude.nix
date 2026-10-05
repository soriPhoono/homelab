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
  };
  den.aspects.sphoono.development = {
    # claude-code is unfree.
    includes = [ (den.batteries.unfree [ "claude-code" ]) ];
    homeManager =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
        programs.claude-code = {
          enable = true;
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
                  fi
                done
              '';
            };
          settings = {
            model = "opus";
            effortLevel = "high";
            # Opt the mem0 plugin's hooks, MCP server and flush worker out
            # of usage telemetry.
            env.MEM0_TELEMETRY = "false";
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
