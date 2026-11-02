{ inputs, ... }: {
  # The npm tarball ships the prebuilt hook bundle, so nothing is built here.
  flake-file.inputs.codex-honcho = {
    url = "https://registry.npmjs.org/@honcho-ai/codex-honcho/-/codex-honcho-0.1.1.tgz";
    flake = false;
  };

  den.aspects.sphoono.development.codex = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        # `codex-honcho install` would write the API key into config.toml and
        # copy the bundle into ~/.codex, so the same pieces are declared here.
        honchoHook = verb: {
          type = "command";
          command = "${lib.getExe pkgs.nodejs} ${inputs.codex-honcho}/dist/codex-honcho.mjs ${verb}";
        };
      in
      {
        programs.codex = {
          enable = true;
          package =
            let
              agent = pkgs.codex;
            in
            pkgs.symlinkJoin {
              inherit (agent) pname;
              inherit (agent) version;
              name = "${agent.name}-with-honcho";

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
                      --run 'export HONCHO_API_KEY="$(cat ${config.sops.secrets."api/honcho-api-key".path})"'
                  fi
                done
              '';
            };
          context = ''
            ${builtins.readFile ../../../assets/documents/user.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/personal-assistant.md}

            ${builtins.readFile ../../../assets/documents/agents/codex.md}
          '';
          settings = {
            features.hooks = true;
            # The hosted Honcho MCP server. The key reaches it through the
            # environment variable the wrapper above exports.
            mcp_servers.honcho = {
              url = "https://mcp.honcho.dev";
              bearer_token_env_var = "HONCHO_API_KEY";
              http_headers = {
                "X-Honcho-User-Name" = "sphoono";
                # Keep in step with hosts.codex in tools/honcho.nix.
                "X-Honcho-Workspace-ID" = "personal-assistant";
                "X-Honcho-Assistant-Name" = "codex";
              };
            };
          };
          # Recall on session start; observe tool calls; write the transcript
          # back every turn and before compaction.
          hooks = {
            SessionStart = [
              {
                matcher = "startup|resume|clear|compact";
                hooks = [
                  (
                    honchoHook "recall"
                    // {
                      timeout = 30;
                      statusMessage = "honcho";
                    }
                  )
                ];
              }
            ];
            UserPromptSubmit = [ { hooks = [ (honchoHook "prompt" // { timeout = 20; }) ]; } ];
            PostToolUse = [
              {
                matcher = "*";
                hooks = [ (honchoHook "observe" // { timeout = 10; }) ];
              }
            ];
            Stop = [ { hooks = [ (honchoHook "writeback" // { timeout = 30; }) ]; } ];
            PreCompact = [
              {
                matcher = "manual|auto";
                hooks = [ (honchoHook "writeback" // { timeout = 30; }) ];
              }
            ];
          };
          skills = {
            honcho-memory = "${inputs.codex-honcho}/skills/honcho-memory";
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
