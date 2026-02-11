_: _final: prev: {
  mcp-server-git = prev.python3Packages.buildPythonApplication rec {
    pname = "mcp-server-git";
    version = "2025.12.18";

    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "servers";
      rev = version;
      hash = "sha256-Km0MjjZhhijynYyju3tMJwsplrpNUr4cJ95TxqgrrR8=";
    };

    sourceRoot = "${src.name}/src/git";

    pyproject = true;

    nativeBuildInputs = with prev.python3Packages; [
      hatchling
      uv
    ];

    propagatedBuildInputs = with prev.python3Packages; [
      # Guessed dependencies, build will fail and tell us what's missing
      mcp
      gitpython
    ];

    makeWrapperArgs = [
      "--prefix PATH : ${prev.lib.makeBinPath [prev.git]}"
    ];

    meta = with prev.lib; {
      description = "MCP server for Git repository operations";
      homepage = "https://github.com/modelcontextprotocol/servers";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
