/**
  9router, a local OpenAI-compatible gateway the coding agents point at. It
  falls back across providers when a subscription quota runs out and fronts
  local models such as Ollama. Providers are added imperatively in the
  dashboard at http://localhost:20128 and persist in the user state directory.

  When OpenCode is enabled it gets 9router as a provider. OpenCode does not
  discover models from an OpenAI-compatible endpoint, so a oneshot service
  lists 9router's `/v1/models` into `opencode.jsonc` beside the managed
  `opencode.json`, which OpenCode merges.
*/
_: {
  den.aspects.sphoono.development."9router" = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        gateway = "http://127.0.0.1:20128/v1";

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
        systemd.user.services."9router" = {
          Unit = {
            Description = "9router AI gateway";
            # The env file is rendered by sops-nix at login. Home Manager
            # restarts sops-nix on every switch, and PartOf carries that
            # restart here, so the service never keeps a stale env file.
            After = [ "sops-nix.service" ];
            PartOf = [ "sops-nix.service" ];
          };
          Service = {
            # The default host is 0.0.0.0, and no API key is required, so the
            # loopback bind is the only access control. --log sends the
            # server's own errors to the journal; they are hidden otherwise.
            ExecStart = "${lib.getExe pkgs._9router} --host 127.0.0.1 --port 20128 --no-browser --skip-update --log";
            EnvironmentFile = config.sops.templates."9router.env".path;
            Environment = [
              "NODE_ENV=production"
              "NEXT_TELEMETRY_DISABLED=1"
              "DATA_DIR=%S/9router"
              "REQUIRE_API_KEY=false"
              # Loopback over plain http, so the cookie cannot be Secure.
              "AUTH_COOKIE_SECURE=false"
              # Request logs hold prompts and code.
              "ENABLE_REQUEST_LOGS=false"
            ];
            StateDirectory = "9router";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };

        programs.opencode.settings.providers."9router" = lib.mkIf config.programs.opencode.enable {
          name = "9router";
          package = "aisdk:@ai-sdk/openai-compatible";
          settings = {
            baseURL = gateway;
            # 9router needs no key on loopback; the SDK wants a non-empty one.
            apiKey = "9router";
          };
        };

        # Refreshes the list whenever 9router (re)starts. Run
        # `opencode-sync-models` after changing providers in the dashboard.
        systemd.user.services.opencode-9router-models = lib.mkIf config.programs.opencode.enable {
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

        sops = {
          secrets = {
            "api/9router-jwt-secret".mode = "0400";
            "api/9router-initial-password".mode = "0400";
          };
          # Rendered at activation, so the values never enter the nix store.
          templates."9router.env".content = ''
            JWT_SECRET=${config.sops.placeholder."api/9router-jwt-secret"}
            INITIAL_PASSWORD=${config.sops.placeholder."api/9router-initial-password"}
          '';
        };
      };
  };
}
