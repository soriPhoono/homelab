{
  den.aspects.sphoono.content-creation.homeManager =
    { lib, pkgs, ... }:
    {
      home.packages = [ pkgs.blender ];

      # Lets Claude Code drive Blender. The server talks to the MCP for
      # Blender addon over localhost:9876; install the addon once with
      # `uvx mcp-for-blender@2.1.3 install-addon`, then start it from the
      # N panel. Not in nixpkgs, so uvx fetches the pinned PyPI release.
      programs.claude-code.mcpServers.blender = {
        command = lib.getExe' pkgs.uv "uvx";
        args = [ "mcp-for-blender@2.1.3" ];
        env.DISABLE_TELEMETRY = "true";
      };
    };
}
