{ den, ... }:
{
  # Antigravity CLI (agy) does outside research for Claude Code and writes it
  # into the shared agent wiki. Login is imperative: run `agy` once per host.
  den.aspects.sphoono.development = {
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];
    homeManager =
      { config, pkgs, ... }:
      let
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
        home.sessionVariables.AGENT_WIKI = "${config.home.homeDirectory}/Shared/AgentWiki";

        # Implementation plans handed to Claude's plan-watch loop are work
        # items, not project history; their outcome lands as commits.
        programs.git.ignores = [ ".agents/plans/" ];

        programs.antigravity-cli = {
          enable = true;
          # Research only: agy writes the wiki and plan files, never touches
          # version control, the nix store or secrets.
          permissions.deny = [
            "command(git)"
            "command(nix)"
            "command(nh)"
            "command(nixos-rebuild)"
            "command(home-manager)"
            "command(sops)"
            "command(sudo)"
          ];
        };

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
