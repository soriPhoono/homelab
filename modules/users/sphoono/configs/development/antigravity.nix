{ den, ... }:
{
  # Antigravity CLI (agy) does outside research for Claude Code and writes it
  # into the shared agent wiki. Login is imperative: run `agy` once per host.
  den.aspects.sphoono.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];
    homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        home = config.home.homeDirectory;
        wiki = "${home}/Shared/AgentWiki";
        obsidianSkills = pkgs.agent-skills.github.kepano.obsidian-skills;
        # Research runs headless (`agy -p`), where any tool needing approval
        # is denied, so everything research needs is allowed explicitly.
        # Targets are path prefixes matched against the resolved path (skills
        # resolve into /nix/store); a `*` inside a path does not match.
        managedSettings = {
          toolPermission = "proceed-in-sandbox";
          enableTerminalSandbox = true;
          permissions = {
            allow = [
              "read_file(/nix/store)"
              "read_file(${home}/.gemini)"
              "read_file(${home}/Projects)"
              "read_url(*)"
              # Research only writes the wiki and the root plan inbox.
              "write_file(${wiki})"
              "write_file(${home}/Projects/.agents/plans)"
            ];
            # Never version control, the nix store or secrets.
            deny = [
              "command(git)"
              "command(nix)"
              "command(nh)"
              "command(nixos-rebuild)"
              "command(home-manager)"
              "command(sops)"
              "command(sudo)"
            ];
          };
        };
        # agy 1.2.9 discovers global skills and rules under ~/.gemini/config/
        # only. The home-manager module's `skills` and `context` options
        # write to ~/.gemini/antigravity-cli/skills and ~/.gemini/*.md, which
        # agy never reads, so both are placed here directly.
        skills = {
          inherit (obsidianSkills) obsidian-markdown defuddle;
          # Research protocol: wiki upkeep, requests from Claude, and plans
          # handed back to Claude.
          llm-wiki = ../../assets/skills/llm-wiki;
          research-intake = ../../assets/skills/research-intake;
          claude-handoff = ../../assets/skills/claude-handoff;
        };
      in
      {
        home.sessionVariables.AGENT_WIKI = wiki;

        # Implementation plans handed to Claude's plan-watch loop are work
        # items, not project history; their outcome lands as commits.
        programs.git.ignores = [ ".agents/plans/" ];

        # Package only. agy rewrites settings.json itself (model choice,
        # trusted workspaces) and replaces a read-only store link, so the
        # module's `settings`/`permissions` are left unset and the managed
        # keys are merged into agy's own file on activation instead.
        programs.antigravity-cli.enable = true;

        home.activation.antigravitySettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="${home}/.gemini/antigravity-cli/settings.json"
          run mkdir -p "$(dirname "$settings")"
          if [ -L "$settings" ]; then
            run rm "$settings"
          fi
          current='{}'
          if [ -e "$settings" ]; then
            current="$(cat "$settings")"
          fi
          merged="$(${lib.getExe pkgs.jq} --argjson managed ${lib.escapeShellArg (builtins.toJSON managedSettings)} \
            '. * $managed' <<<"$current")"
          if [ -z "''${DRY_RUN:-}" ]; then
            printf '%s\n' "$merged" > "$settings"
            chmod 600 "$settings"
          fi
        '';

        home.file = {
          ".gemini/config/rules/sphoono.md".text = ''
            ---
            trigger: always_on
            ---

            ${builtins.readFile ../../assets/documents/user.md}

            ${builtins.readFile ../../assets/documents/antigravity/AGENTS.md}
          '';
        }
        // builtins.listToAttrs (
          map (name: {
            name = ".gemini/config/skills/${name}";
            value = {
              source = skills.${name};
              recursive = true;
            };
          }) (builtins.attrNames skills)
        );
      };
  };
}
