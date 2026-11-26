{ den, inputs, ... }:
{
  # mem0's monorepo, for its Claude Code plugin under
  # integrations/claude-code-plugin.
  flake-file.inputs.mem0 = {
    url = "github:mem0ai/mem0";
    flake = false;
  };

  # Claude Code, configured like the opencode aspect: the same user context,
  # agent roles, skills and MCP servers, written to ~/.claude by Home
  # Manager's programs.claude-code. The skill inputs are declared by the
  # opencode aspect.
  den.aspects.sphoono.development.agents.claude-code = {
    includes = [ (den.batteries.unfree [ "claude-code" ]) ];

    homeManager = _: {
      imports = [
        (import ./_private { inherit inputs; })
      ];

      nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
    };
  };
}
