{ den, inputs, ... }: {
  flake-file.inputs.nix-skills.url = "github:sudosubin/nix-skills";
  den.aspects.sphoono.configs.claude = {
    # claude-code is unfree.
    includes = [ (den.batteries.unfree [ "claude-code" ]) ];
    homeManager =
      { pkgs, ... }:
      let
        mem0Src = pkgs.fetchFromGitHub {
          owner = "mem0ai";
          repo = "mem0";
          rev = "v2.2.1";
          sha256 = "sha256-C7E7Xd1+7Vy0ZwRIjblihexQTkS2YBPx5Sogz6ACYXs=";
        };
        # nix-skills has not yet indexed these two repos (tracked in its
        # sources.json but no skill data generated), so their skills are
        # fetched directly instead of through pkgs.agent-skills.
        awesomeCopilotSrc = pkgs.fetchFromGitHub {
          owner = "github";
          repo = "awesome-copilot";
          rev = "d6131471b85fbb4799e64175ebc42c9309ecc28a";
          sha256 = "sha256-4B7Dg0YcRS0+J7wt8vko1A5FoWOhrEuYIx+e/AIRgss=";
        };
        mattpocockSkillsSrc = pkgs.fetchFromGitHub {
          owner = "mattpocock";
          repo = "skills";
          rev = "d81f3a183412e71a5b1e84ca21bc1a35eea03a60";
          sha256 = "sha256-zQ/wVrcHjIC+UjP4nDw3HARMqZd6LIDFmHKlp8AADYI=";
        };
      in
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
        programs.claude-code = {
          enable = true;
          context = ''
            ${builtins.readFile ../../assets/documents/user.md}

            ${builtins.readFile ../../assets/documents/claude/AGENTS.md}
          '';
          marketplaces = {
            mem0 = mem0Src;
          };
          plugins = {
            # The marketplace manifest points the "mem0" plugin at this
            # subdirectory of the repo, not the repo root.
            mem0 = "${mem0Src}/integrations/claude-code-plugin";
          };
          skills = {
            stop-slop = pkgs.agent-skills.github.hardikpandya.stop-slop.stop-slop;
            grilling = "${mattpocockSkillsSrc}/skills/productivity/grilling";
            grill-me = "${mattpocockSkillsSrc}/skills/productivity/grill-me";
            grill-with-docs = "${mattpocockSkillsSrc}/skills/engineering/grill-with-docs";
            # Create agentic integrations
            create-agentsmd = "${awesomeCopilotSrc}/skills/create-agentsmd";
            create-readme = "${awesomeCopilotSrc}/skills/create-readme";
            # Work with git repos
            git-commit = "${awesomeCopilotSrc}/skills/git-commit";
          };
        };
      };
  };
}
