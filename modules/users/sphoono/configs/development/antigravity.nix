{ den, ... }:
{
  # Antigravity CLI (agy) does outside research for Claude Code and writes it
  # into the shared agent wiki. Login is imperative: run `agy` once per host.
  den.aspects.sphoono.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];
    homeManager =
      { config, pkgs, ... }:
      let
        home = config.home.homeDirectory;
        wiki = "${home}/Shared/AgentWiki";
        obsidianSkills = pkgs.agent-skills.github.kepano.obsidian-skills;
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

        programs.antigravity-cli = {
          enable = true;
          settings = {
            # What agy saved during the interactive login, declared because
            # its own writes to this file are replaced on every switch (see
            # below).
            model = "Gemini 3.8 Flash (High)";
            trustedWorkspaces = [ "${home}/Projects/homelab" ];
            toolPermission = "proceed-in-sandbox";
            # Launched from Claude Code, every sandboxed command fails with
            # "connecting to sandbox server: ... connection reset by peer"
            # and agy retries it unsandboxed, which print mode denies. Shell
            # access is limited by the read-only command allow-list instead.
            enableTerminalSandbox = false;
          };
          # Research runs headless (`agy -p`), where any tool needing approval
          # is denied, so everything research needs is allowed explicitly.
          # Targets are path prefixes matched against the resolved path
          # (skills resolve into /nix/store); a `*` inside a path does not
          # match.
          permissions = {
            allow = [
              "read_file(/nix/store)"
              "read_file(${home}/.gemini)"
              "read_file(${home}/Projects)"
              "read_url(*)"
              # Read-only shell commands; any other command is denied, which
              # ends a print-mode run.
              "command(ls)"
              "command(cat)"
              "command(head)"
              "command(tail)"
              "command(wc)"
              "command(grep)"
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

        home.file = {
          # agy replaces this link with a regular file whenever it saves a
          # setting (the model picked at login, a trusted workspace) and on
          # its first launch while the file is a link. Without force, the
          # next switch backs it up to settings.json.hm-backup and the one
          # after fails because that backup already exists.
          ".gemini/antigravity-cli/settings.json".force = true;

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
