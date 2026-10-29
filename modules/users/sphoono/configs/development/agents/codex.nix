{ inputs, ... }: {
  den.aspects.sphoono.development.codex = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        # Shared with Claude Code; the mem0 Codex plugin reads the same key.
        sops.secrets."api/mem0-api-key" = { };
        programs.codex = {
          enable = true;
          package =
            let
              agent = pkgs.codex;
            in
            pkgs.symlinkJoin {
              inherit (agent) pname;
              inherit (agent) version;
              name = "${agent.name}-with-mem0";

              paths = [ agent ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]} \
                      --run 'export MEM0_API_KEY="$(cat ${config.sops.secrets."api/mem0-api-key".path})"' \
                      --run 'export MEM0_TELEMETRY="false"'
                  fi
                done
              '';
            };
          context = ''
            ${builtins.readFile ../../../assets/documents/user.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/coding.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/nix-infrastructure.md}

            ${builtins.readFile ../../../assets/documents/agents/codex.md}
          '';
          # The mem0 Codex plugin ships lifecycle hooks (recall on session start,
          # capture on stop), its memory MCP server and /mem0 skills. Hooks run
          # through the python3 the wrapper above puts on PATH.
          plugins = [ "${inputs.mem0}/integrations/codex-plugin" ];
          skills = {
            code-documentation = "${inputs.awesome-ai-agent-skills}/code-and-development/code-documentation";
            code-review = "${inputs.awesome-ai-agent-skills}/code-and-development/code-review";
            debugging = "${inputs.awesome-ai-agent-skills}/code-and-development/debugging";
            refactoring = "${inputs.awesome-ai-agent-skills}/code-and-development/refactoring";
            testing = "${inputs.awesome-ai-agent-skills}/code-and-development/testing";
            version-control = "${inputs.awesome-ai-agent-skills}/code-and-development/version-control";
          };
        };
      };
  };
}
