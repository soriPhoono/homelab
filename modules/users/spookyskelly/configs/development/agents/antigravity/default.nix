{ den, inputs, ... }:
{
  # Antigravity, spookyskelly's coding agent: user context, skills and MCP
  # servers, written to ~/.gemini by Home Manager's programs.antigravity-cli.
  den.aspects.spookyskelly.development.agents.antigravity = {
    # antigravity-cli (`agy`): the terminal agent, and the entry point for
    # driving Antigravity from scripts and other agents.
    includes = [ (den.batteries.unfree [ "antigravity-cli" ]) ];

    homeManager =
      { lib, pkgs, ... }:
      {
        programs.antigravity-cli = {
          enable = true;
          context.GEMINI = builtins.readFile ../assets/USER.md;
          mcpServers.n8n.serverUrl = "https://agents.cryptic-coders.net/mcp-server/http";
          skills = import ../_private/skills.nix { inherit inputs lib pkgs; };
        };

        nixpkgs.overlays = [ inputs.nix-skills.overlays.default ];
      };

    # antigravity-hub: the desktop interface for managing Antigravity agents
    # across projects. It reads the same ~/.gemini configuration as the CLI.
    desktop = {
      includes = [ (den.batteries.unfree [ "antigravity-hub" ]) ];

      homeManager =
        { pkgs, ... }:
        {
          home.packages = [ pkgs.antigravity-hub ];
        };
    };
  };
}
