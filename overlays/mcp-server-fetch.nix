_: _final: prev: {
  mcp-server-fetch = prev.python3Packages.buildPythonApplication rec {
    pname = "mcp-server-fetch";
    version = "2025.12.18";

    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "servers";
      rev = version;
      hash = "sha256-Km0MjjZhhijynYyju3tMJwsplrpNUr4cJ95TxqgrrR8=";
    };

    sourceRoot = "${src.name}/src/fetch";

    pyproject = true;

    # Relax httpx constraint
    postPatch = ''
      substituteInPlace pyproject.toml \
        --replace-fail '"httpx<0.28"' '"httpx>=0.23.0"'
    '';

    nativeBuildInputs = with prev.python3Packages; [
      hatchling
      uv
    ];

    propagatedBuildInputs = with prev.python3Packages; [
      mcp
      beautifulsoup4
      httpx
      defusedxml
      anyio
      markdownify
      protego
      readabilipy
      requests
      pydantic
    ];

    meta = with prev.lib; {
      description = "MCP server for fetching web content";
      homepage = "https://github.com/modelcontextprotocol/servers";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
