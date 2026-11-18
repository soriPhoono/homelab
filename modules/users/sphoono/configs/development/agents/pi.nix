/**
  Pi, the second coding agent beside OpenCode: a minimal harness meant to be
  shaped with extensions, skills and prompt templates, built from its tagged
  source by nixpkgs so the code that runs is the code that can be audited.
*/
{ den, inputs, ... }:
{
  den.aspects.sphoono.development.pi = {
    includes = [
      den.aspects.sphoono.development.ninerouter
    ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        cfg = config.programs.pi-coding-agent;
        gateway = config.development.ninerouter.url;
        keyFile = config.sops.secrets."api/9router-api-key".path;

        # Pi does not discover the models of an OpenAI-compatible endpoint, so
        # a oneshot lists the gateway's `/v1/models` into models.json. The key
        # stays out of the file: Pi runs the `!cat` itself on each request.
        syncModels = pkgs.writeShellApplication {
          name = "pi-sync-models";
          runtimeInputs = [
            pkgs.curl
            pkgs.jq
            pkgs.coreutils
          ];
          text = ''
            dest="${cfg.configDir}/models.json"
            mkdir -p "$(dirname "$dest")"
            tmp="$(mktemp)"
            trap 'rm -f "$tmp" "$tmp.out"' EXIT

            # The tailnet may still be coming up at login.
            for _ in $(seq 1 30); do
              if curl -fsS --max-time 5 -H "Authorization: Bearer $(cat ${keyFile})" \
                -o "$tmp" ${gateway}/models; then
                break
              fi
              sleep 2
            done
            [ -s "$tmp" ] || { echo "gateway did not answer; keeping the old list" >&2; exit 1; }

            jq --arg url "${gateway}" --arg key "!cat ${keyFile}" '
              { "$schema": "https://pi.dev/schemas/models.schema.json",
                providers: { "9router": {
                  baseUrl: $url,
                  api: "openai-completions",
                  apiKey: $key,
                  models: (.data | map({
                    id: .id,
                    name: .id,
                    reasoning: (.capabilities.reasoning // false),
                    input: (["text"] + (if .capabilities.vision then ["image"] else [] end)),
                    contextWindow: (.context_length // 128000),
                    maxTokens: (.max_completion_tokens // 16384)
                  }))
                } } }
            ' "$tmp" > "$tmp.out"

            mv "$tmp.out" "$dest"
            echo "wrote $(jq '.providers."9router".models | length' "$dest") models to $dest"
          '';
        };

        essentials = lib.genAttrs [
          "code-documentation"
          "code-review"
          "debugging"
          "refactoring"
          "testing"
          "version-control"
        ] (name: "${inputs.awesome-ai-agent-skills}/code-and-development/${name}");

        skills = essentials // {
          stop-slop = pkgs.agent-skills.github.hardikpandya.stop-slop.stop-slop;
          grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
          grill-with-docs = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
          git-commit = "${inputs.awesome-copilot}/skills/git-commit";
        };
      in
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];

        sops.secrets."api/9router-api-key" = { };

        home.packages = [ syncModels ];

        # Run `pi-sync-models` after changing models in the 9router dashboard.
        systemd.user.services.pi-9router-models = {
          Unit = {
            Description = "List 9router models for Pi";
            After = [ "sops-nix.service" ];
            Wants = [ "sops-nix.service" ];
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

        programs.pi-coding-agent = {
          enable = true;
          # For the agent's tools; the package already carries ripgrep and fd.
          extraPackages = [
            pkgs.nodejs
            pkgs.python3
          ];

          # Writable, so `/model` and `/thinking` can save defaults with
          # Ctrl+S. The values below win again at each activation.
          mutableSettings = true;
          settings = {
            defaultProvider = "9router";
            enableInstallTelemetry = false;
            skills = lib.attrValues skills;
          };

          context = ''
            ${builtins.readFile ../../../assets/documents/user.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/coding.md}

            ${builtins.readFile ../../../assets/documents/agent-roles/nix-infrastructure.md}

            ${builtins.readFile ../../../assets/documents/agents/pi.md}
          '';
        };
      };
  };
}
