/**
  OpenCode, pointed at the local 9router gateway. The gateway is the same on
  every host, so the provider is declared everywhere; a model only answers
  where its backend runs (the Gemma 4 build lives on desktop-ares).

  OpenCode does not discover models from an OpenAI-compatible endpoint, so a
  oneshot service lists 9router's `/v1/models` into `opencode.jsonc` beside
  the managed `opencode.json`. OpenCode merges the two. Every model, the
  local Gemma included, comes from that list with the gateway's own limits.
*/
_: {
  den.aspects.sphoono.development.opencode = {
    homeManager =
      {
        lib,
        pkgs,
        ...
      }:
      let
        gateway = "http://127.0.0.1:20128/v1";

        # OpenCode reads ~/.claude/skills, which Home Manager fills for Claude
        # Code: 177 skills, about 17.7k tokens on every request. The switch
        # hides them; project-level CLAUDE.md files keep loading.
        opencode = pkgs.symlinkJoin {
          inherit (pkgs.opencode) pname version meta;
          name = "${pkgs.opencode.name}-wrapped";
          paths = [ pkgs.opencode ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/opencode --set OPENCODE_DISABLE_CLAUDE_CODE_SKILLS 1
          '';
        };

        syncModels = pkgs.writeShellApplication {
          name = "opencode-sync-models";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
          ];
          text = ''
            dest="''${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.jsonc"
            mkdir -p "$(dirname "$dest")"
            tmp="$(mktemp)"
            trap 'rm -f "$tmp" "$tmp.out"' EXIT

            # 9router may still be starting.
            for _ in $(seq 1 30); do
              if curl -fsS --max-time 5 -o "$tmp" ${gateway}/models; then
                break
              fi
              sleep 2
            done
            [ -s "$tmp" ] || { echo "9router did not answer; keeping the old list" >&2; exit 1; }

            # OpenCode 2 model schema: capabilities and limit.
            jq '
              { providers: { "9router": { models: (
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
        home.packages = [ syncModels ];

        programs.opencode = {
          enable = true;
          package = opencode;
          # Claude's prompt, verbatim: v2 does not read ~/.claude/CLAUDE.md.
          context = ''
            ${builtins.readFile ../../../assets/documents/user.md}

            ${builtins.readFile ../../../assets/documents/claude/AGENTS.md}
          '';
          settings = {
            "$schema" = "https://opencode.ai/config.json";
            providers."9router" = {
              name = "9router";
              package = "aisdk:@ai-sdk/openai-compatible";
              settings = {
                baseURL = gateway;
                # 9router needs no key on loopback; the SDK wants a non-empty one.
                apiKey = "9router";
              };
            };
            # Session titles go to a cheap chat chain on 9router, so they
            # never queue on the local GPU.
            agents.title.model = "9router/Summary-models";
            permissions = [
              # find-skills installs third-party skills through npx.
              {
                action = "shell";
                resource = "npx skills add *";
                effect = "ask";
              }
              # v2 allows leaving the project by default; v1 asked.
              {
                action = "external_directory";
                resource = "*";
                effect = "ask";
              }
            ];
          };
        };

        # Refreshes the list whenever 9router (re)starts. Run
        # `opencode-sync-models` after changing providers in the dashboard.
        systemd.user.services.opencode-9router-models = {
          Unit = {
            Description = "List 9router models for OpenCode";
            Wants = [ "9router.service" ];
            After = [ "9router.service" ];
            PartOf = [ "9router.service" ];
          };
          Service = {
            Type = "oneshot";
            # Stays active so a 9router restart propagates here.
            RemainAfterExit = true;
            ExecStart = lib.getExe syncModels;
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
  };
}
