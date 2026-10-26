/**
  OpenCode, pointed at the local 9router gateway. The gateway is the same on
  every host, so the provider is declared everywhere; a model only answers
  where its backend runs (the Gemma 4 build lives on desktop-ares).

  OpenCode does not discover models from an OpenAI-compatible endpoint, so a
  oneshot service lists 9router's `/v1/models` into `opencode.jsonc` beside
  the managed `opencode.json`. OpenCode merges the two. Models declared here
  keep their hand-tuned limits and are skipped by the generated file.
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

        # Declared by hand because the gateway reports a rounded 128000
        # context for it, not the 131072 Ollama is configured with.
        declaredModels = {
          "desktop-ollama/gemma4:26b-a4b-it-qat" = {
            name = "Gemma 4 26B-A4B QAT (desktop-ares)";
            # Matches OLLAMA_CONTEXT_LENGTH. Output is generous because the
            # model reasons first and an exhausted budget returns nothing.
            limit = {
              context = 131072;
              output = 32768;
            };
          };
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

            jq --argjson skip '${builtins.toJSON (builtins.attrNames declaredModels)}' '
              { provider: { "9router": { models: (
                .data
                | map(select(.id as $id | $skip | index($id) | not))
                | map({ key: .id, value: {
                    name: .id,
                    tool_call: (.capabilities.tools // false),
                    reasoning: (.capabilities.reasoning // false),
                    limit: {
                      context: (.context_length // 128000),
                      output: (.max_completion_tokens // 8192)
                    }
                  } })
                | from_entries
              ) } } }
            ' "$tmp" > "$tmp.out"

            mv "$tmp.out" "$dest"
            echo "wrote $(jq '.provider."9router".models | length' "$dest") models to $dest"
          '';
        };
      in
      {
        home.packages = [ syncModels ];

        programs.opencode = {
          enable = true;
          settings = {
            "$schema" = "https://opencode.ai/config.json";
            provider."9router" = {
              npm = "@ai-sdk/openai-compatible";
              name = "9router";
              options = {
                baseURL = gateway;
                # 9router needs no key on loopback; the SDK wants a non-empty one.
                apiKey = "9router";
              };
              models = declaredModels;
            };
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
