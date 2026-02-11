_: _final: prev: {
  mcp-server-mermaid = prev.buildNpmPackage rec {
    pname = "mcp-server-mermaid";
    version = "0.2.0";

    src = prev.fetchFromGitHub {
      owner = "peng-shawn";
      repo = "mermaid-mcp-server";
      rev = "v${version}";
      # Hash verified
      hash = "sha256-W4sJqHOpo94gLOxjip7F9pNLojFC67AUYi77OUAHJOY=";
    };

    # Will need re-hash changed strategy (ignore-scripts)
    npmDepsHash = "sha256-Guju/oizz5Ikw37uVZCJP0MSafWCKnAJ+HemZhOw/6s=";

    nodejs = prev.nodejs_22;
    npmFlags = ["--ignore-scripts"];

    nativeBuildInputs = [prev.makeWrapper];

    # Manually build since we ignore scripts
    buildPhase = ''
      runHook preBuild
      npx tsc
      chmod +x dist/*.js
      runHook postBuild
    '';

    doCheck = false;
    dontNpmPrune = true;

    postInstall = ''
      wrapProgram $out/bin/mermaid-mcp-server \
        --set PUPPETEER_EXECUTABLE_PATH "${prev.chromium}/bin/chromium"
    '';

    meta = with prev.lib; {
      description = "MCP server for Mermaid diagram rendering";
      homepage = "https://github.com/peng-shawn/mermaid-mcp-server";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
