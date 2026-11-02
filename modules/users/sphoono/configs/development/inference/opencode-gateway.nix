/**
  OpenCode's provider for the 9router gateway on sphoono-vps, reached over the
  tailnet through docktail. OpenCode does not discover models from an
  OpenAI-compatible endpoint, so a oneshot lists the gateway's `/v1/models`
  into `opencode.jsonc` beside the managed `opencode.json`, which OpenCode
  merges. The API key is entered imperatively with `/connect` in OpenCode,
  which keeps it in the `credential` table of its database. The oneshot only
  reads it from there to list models; nothing secret is written to a file.
*/
_: {
  den.aspects.sphoono.development.opencode-gateway = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
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
      lib.mkIf config.programs.opencode.enable {
        home.packages = [ syncModels ];

        programs.opencode.settings.providers."9router" = {
          name = "9router";
          package = "aisdk:@ai-sdk/openai-compatible";
          settings.baseURL = gateway;
        };

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
      };
  };
}
