/**
  OpenCode, pointed at the local 9router gateway. The gateway is the same on
  every host, so the provider is declared everywhere; a model only answers
  where its backend runs (the Gemma 4 build lives on desktop-ares).

  OpenCode does not discover models from an OpenAI-compatible endpoint, so a
  oneshot service lists 9router's `/v1/models` into `opencode.jsonc` beside
  the managed `opencode.json`. OpenCode merges the two. Every model, the
  local Gemma included, comes from that list with the gateway's own limits.
*/
{ inputs, ... }:
{
  den.aspects.sphoono.development.opencode = {
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        gateway = "http://127.0.0.1:20128/v1";

        # Skills are found in the pinned inputs at evaluation time, so a
        # bumped input brings its new skills along. A skill is any
        # directory that holds a SKILL.md.
        skillDirs =
          base:
          lib.mapAttrs (name: _: base + "/${name}") (
            lib.filterAttrs (
              name: type: type == "directory" && builtins.pathExists (base + "/${name}/SKILL.md")
            ) (builtins.readDir base)
          );
        skillDirsIn = base: dirs: lib.mergeAttrsList (map (dir: skillDirs (base + "/${dir}")) dirs);

        # mattpocock's library without in-progress and deprecated.
        mattpocock = skillDirsIn inputs.mattpocock-skills [
          "skills/engineering"
          "skills/misc"
          "skills/productivity"
        ];
        # Every category of awesome-ai-agent-skills (103 skills). Merged
        # after mattpocock, so its code-review wins the one name clash.
        awesome = skillDirsIn inputs.awesome-ai-agent-skills (
          lib.attrNames (
            lib.filterAttrs (_: type: type == "directory") (builtins.readDir inputs.awesome-ai-agent-skills)
          )
        );
        superpowers = skillDirs (inputs.superpowers + "/skills");
        agentSkills = pkgs.agent-skills.github;
        skills =
          mattpocock
          // awesome
          // superpowers
          // {
            create-agentsmd = inputs.awesome-copilot + "/skills/create-agentsmd";
            create-readme = inputs.awesome-copilot + "/skills/create-readme";
            git-commit = inputs.awesome-copilot + "/skills/git-commit";
            stop-slop = agentSkills.hardikpandya.stop-slop.stop-slop;
            # Lets an agent search skills.sh and install a skill into a
            # project.
            inherit (agentSkills.vercel-labs.skills) find-skills;
          }
          # The n8n skills that do not depend on czlonkowski's separate
          # n8n-mcp server; n8n's own MCP server covers the rest.
          // {
            inherit (agentSkills.czlonkowski.n8n-skills)
              n8n-expression-syntax
              n8n-code-javascript
              n8n-code-python
              n8n-code-tool
              n8n-binary-and-data
              ;
          }
          // {
            inherit (agentSkills.kepano.obsidian-skills)
              defuddle
              json-canvas
              knap
              obsidian-bases
              obsidian-cli
              obsidian-markdown
              ;
          };

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

        # Claude plugin agents and commands, converted to OpenCode 2 markdown
        # at build time. Frontmatter becomes description plus mode (agents
        # only); the model is dropped so they use the session model, and
        # color names become hex. Agents that listed read-only tools get
        # edit and shell denied. Bodies are kept verbatim, so references to
        # Claude's TodoWrite and Task tools remain.
        plugins = inputs.claude-plugins-official + "/plugins";
        mdFiles =
          dir:
          lib.attrNames (
            lib.filterAttrs (n: t: t == "regular" && lib.hasSuffix ".md" n) (builtins.readDir dir)
          );
        colors = {
          cyan = "#06b6d4";
          green = "#22c55e";
          pink = "#ec4899";
          red = "#ef4444";
          yellow = "#eab308";
        };
        # Frontmatter fields (a key: line plus its indented continuation
        # lines) and the body.
        splitMd =
          text:
          let
            lines = lib.splitString "\n" text;
            total = builtins.length lines;
            fmLength = lib.lists.findFirstIndex (l: l == "---") 0 (lib.sublist 1 total lines);
            fm = lib.sublist 1 fmLength lines;
            fields = lib.foldl' (
              acc: l:
              if builtins.match "[a-z-]+:.*" l != null then
                acc
                ++ [
                  {
                    key = lib.head (lib.splitString ":" l);
                    lines = [ l ];
                  }
                ]
              else
                lib.init acc ++ [ (lib.last acc // { lines = (lib.last acc).lines ++ [ l ]; }) ]
            ) [ ] fm;
          in
          {
            inherit fields;
            body = lib.sublist (fmLength + 2) total lines;
          };
        fieldOf = fields: key: lib.findFirst (f: f.key == key) null fields;
        render = fm: body: "---\n${lib.concatStringsSep "\n" fm}\n---\n${lib.concatStringsSep "\n" body}";
        toAgent =
          file:
          let
            md = splitMd (builtins.readFile file);
            color = fieldOf md.fields "color";
            colorName =
              if color == null then "" else lib.trim (lib.removePrefix "color:" (lib.head color.lines));
          in
          render (
            (fieldOf md.fields "description").lines
            ++ [ "mode: subagent" ]
            ++ lib.optional (colors ? ${colorName}) ''color: "${colors.${colorName}}"''
            ++ lib.optionals (fieldOf md.fields "tools" != null) [
              "permissions:"
              "  - action: edit"
              "    resource: \"*\""
              "    effect: deny"
              "  - action: shell"
              "    resource: \"*\""
              "    effect: deny"
            ]
          ) md.body;
        toCommand =
          file:
          let
            md = splitMd (builtins.readFile file);
          in
          render (fieldOf md.fields "description").lines md.body;
        fromPlugin =
          plugin: kind: convert: namespaced:
          lib.listToAttrs (
            map (
              file:
              lib.nameValuePair ((lib.optionalString namespaced "${plugin}/") + lib.removeSuffix ".md" file) (
                convert (plugins + "/${plugin}/${kind}/${file}")
              )
            ) (mdFiles (plugins + "/${plugin}/${kind}"))
          );
        pluginNames = [
          "feature-dev"
          "pr-review-toolkit"
        ];
        agents = lib.mergeAttrsList (map (plugin: fromPlugin plugin "agents" toAgent true) pluginNames);
        commands = lib.mergeAttrsList (
          map (plugin: fromPlugin plugin "commands" toCommand false) pluginNames
        );

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

        # Read by the mem0 MCP entry above; also declared by the Claude and
        # Antigravity aspects with the same mode.
        sops.secrets."api/mem0-api-key".mode = "0400";

        # Provides pkgs.agent-skills; the Claude aspect adds it too, which is
        # harmless.
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];

        programs.opencode = {
          enable = true;
          package = opencode;
          inherit skills agents commands;
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
            # Always-on tools. Hosted servers sign in with OAuth (run
            # `opencode mcp auth <name>` once); nothing sensitive is stored
            # in Nix. Project-specific servers live in each repo's config.
            mcp.servers = {
              notion = {
                type = "remote";
                url = "https://mcp.notion.com/mcp";
              };
              n8n = {
                type = "remote";
                url = "https://agents.cryptic-coders.net/mcp-server/http";
              };
              # Works without a key; a key only raises the rate limit.
              context7 = {
                type = "remote";
                url = "https://mcp.context7.com/mcp";
                oauth = false;
              };
              # The mem0 plugin targets OpenCode 1 and fails to load in 2, so
              # the hosted server stands in. The existing sops key is read
              # from its path at startup, never inlined.
              mem0 = {
                type = "remote";
                url = "https://mcp.mem0.ai/mcp/";
                oauth = false;
                headers.Authorization = "Bearer {file:${config.sops.secrets."api/mem0-api-key".path}}";
              };
              # nixpkgs marks mcp-nixos's dependency broken until the channel
              # passes 2026-10-25, so the PyPI release runs through uvx, like
              # Headroom. Swap for pkgs.mcp-nixos once it builds again.
              nixos = {
                type = "local";
                command = [
                  (lib.getExe' pkgs.uv "uvx")
                  "--python"
                  (lib.getExe pkgs.python313)
                  "--from"
                  "mcp-nixos==3.1.0"
                  "mcp-nixos"
                ];
                environment = {
                  UV_PYTHON_DOWNLOADS = "never";
                  LD_LIBRARY_PATH = lib.makeLibraryPath [
                    pkgs.stdenv.cc.cc.lib
                    pkgs.zlib
                  ];
                };
                # The first start downloads the package.
                timeout.startup = 120000;
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
