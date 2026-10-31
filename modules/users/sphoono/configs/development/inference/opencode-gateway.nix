/**
  OpenCode's provider for the 9router gateway on sphoono-vps, reached over the
  tailnet through docktail. OpenCode does not discover models from an
  OpenAI-compatible endpoint, so a oneshot lists the gateway's `/v1/models`
  into `opencode.jsonc` beside the managed `opencode.json`, which OpenCode
  merges. The API key is read from its sops file at run time and written only
  to that file in `~/.config`, never to the nix store.
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
        # Fill in with the tailnet's MagicDNS name.
        tailnetDomain = "tailnet-name.ts.net";
        gateway = "https://sphoono-vps-9router.${tailnetDomain}/v1";
        keyFile = config.sops.secrets."api/9router-api-key".path;

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

            key="$(tr -d '\n' < ${keyFile})"
            [ -n "$key" ] || { echo "empty API key in ${keyFile}" >&2; exit 1; }

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
            jq --arg key "$key" '
              { providers: { "9router": {
                settings: { apiKey: $key },
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

            chmod 600 "$tmp.out"
            mv "$tmp.out" "$dest"
            echo "wrote $(jq '.providers."9router".models | length' "$dest") models to $dest"
          '';
        };
      in
      lib.mkIf config.programs.opencode.enable {
        programs.opencode.settings.providers."9router" = {
          name = "9router";
          package = "aisdk:@ai-sdk/openai-compatible";
          settings.baseURL = gateway;
        };

        sops.secrets."api/9router-api-key".mode = "0400";

        # Run `opencode-sync-models` after changing providers in the dashboard.
        systemd.user.services.opencode-9router-models = {
          Unit = {
            Description = "List 9router models for OpenCode";
            After = [ "sops-nix.service" ];
          };
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
