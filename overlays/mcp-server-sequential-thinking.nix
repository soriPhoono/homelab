_: _final: prev: {
  mcp-server-sequential-thinking = prev.buildNpmPackage rec {
    pname = "mcp-server-sequential-thinking";
    version = "2025.12.18";

    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "servers";
      rev = version;
      hash = "sha256-Km0MjjZhhijynYyju3tMJwsplrpNUr4cJ95TxqgrrR8=";
    };

    npmWorkspace = "src/sequentialthinking";

    # Will need re-hash due to postPatch changes
    npmDepsHash = "sha256-wluSvNnZcIz2XyXqmmego+vYThT3EtzakJsamzhgb6g=";

    nodejs = prev.nodejs_22;
    nativeBuildInputs = [prev.jq];

    # Remove scripts to avoid lifecycle failures in sandbox
    # This keeps package-lock.json so npm ci works
    postPatch = ''
      find . -name "package.json" -print0 | xargs -0 -I {} sh -c '${prev.jq}/bin/jq "del(.scripts)" {} > {}.tmp && mv {}.tmp {}'
    '';

    # Manually build since we removed the scripts
    buildPhase = ''
      runHook preBuild
      cd src/sequentialthinking
      npx tsc
      chmod +x dist/*.js
      cd ../..
      runHook postBuild
    '';

    preFixup = ''
      find $out -type l ! -exec test -e {} \; -delete
    '';

    doCheck = false;
    dontNpmPrune = true;

    meta = with prev.lib; {
      description = "MCP server for structured sequential thinking and reasoning";
      homepage = "https://github.com/modelcontextprotocol/servers";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
