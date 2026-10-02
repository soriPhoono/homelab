{
  den,
  inputs,
  lib,
  ...
}:
{
  flake-file.inputs = {
    nix-skills.url = "github:sudosubin/nix-skills";
    mem0 = {
      url = "github:mem0ai/mem0/v2.2.1";
      flake = false;
    };
    # nix-skills has not yet indexed these two repos (tracked in its
    # sources.json but no skill data generated), so their skills are
    # taken directly instead of through pkgs.agent-skills.
    awesome-copilot = {
      url = "github:github/awesome-copilot/d6131471b85fbb4799e64175ebc42c9309ecc28a";
      flake = false;
    };
    mattpocock-skills = {
      url = "github:mattpocock/skills/d81f3a183412e71a5b1e84ca21bc1a35eea03a60";
      flake = false;
    };
  };
  den.aspects.sphoono.development = {
    # claude-code is unfree.
    includes = [ (den.batteries.unfree [ "claude-code" ]) ];
    homeManager =
      { pkgs, ... }:
      {
        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
        programs.claude-code = {
          enable = true;
          package =
            let
              agent = pkgs.claude-code;
            in
            pkgs.symlinkJoin {
              inherit (agent) pname;
              inherit (agent) version;
              name = "${agent.name}-with-python";

              paths = [ agent ];
              buildInputs = [ pkgs.makeWrapper ];
              postBuild = ''
                for bin in $out/bin/*; do
                  if [ -f "$bin" ] && [ -x "$bin" ]; then
                    wrapProgram "$bin" \
                      --prefix PATH : ${lib.makeBinPath [ pkgs.python3 ]}
                  fi
                done
              '';
            };
          settings = {
            model = "opus";
            effortLevel = "high";
          };
          context = ''
            ${builtins.readFile ../../assets/documents/user.md}

            ${builtins.readFile ../../assets/documents/claude/AGENTS.md}
          '';
          marketplaces = {
            inherit (inputs) mem0;
          };
          plugins = {
            # The marketplace manifest points the "mem0" plugin at this
            # subdirectory of the repo, not the repo root.
            mem0 = "${inputs.mem0}/integrations/claude-code-plugin";
          };
          skills = {
            # Writing
            stop-slop = pkgs.agent-skills.github.hardikpandya.stop-slop.stop-slop;
            # Thinking
            grilling = "${inputs.mattpocock-skills}/skills/productivity/grilling";
            grill-me = "${inputs.mattpocock-skills}/skills/productivity/grill-me";
            grill-with-docs = "${inputs.mattpocock-skills}/skills/engineering/grill-with-docs";
            # Create agentic integrations
            create-agentsmd = "${inputs.awesome-copilot}/skills/create-agentsmd";
            create-readme = "${inputs.awesome-copilot}/skills/create-readme";
            # Work with git repos
            git-commit = "${inputs.awesome-copilot}/skills/git-commit";
          };
        };
      };
  };
}
