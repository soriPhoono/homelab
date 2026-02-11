_: _final: prev: {
  mcp-server-memory = prev.buildNpmPackage rec {
    pname = "mcp-server-memory";
    version = "2026.1.26";

    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "servers";
      rev = version;
      hash = "sha256-uULXUEHFZpYm/fmF6PkOFCxS+B+0q3dMveLG+3JHrhk=";
    };

    npmWorkspace = "src/memory";

    # Will need re-hash due to postPatch changes
    npmDepsHash = "sha256-jmz4JdpeHH07vJQFntBwrENbJaIcOuZMb7+qf497VOE=";

    nodejs = prev.nodejs_22;

    nativeBuildInputs = [prev.jq prev.makeWrapper];

    # Remove scripts to avoid lifecycle failures in sandbox
    # This keeps package-lock.json so npm ci works (it doesn't validate scripts)
    postPatch = ''
      find . -name "package.json" -print0 | xargs -0 -I {} sh -c '${prev.jq}/bin/jq "del(.scripts)" {} > {}.tmp && mv {}.tmp {}'
    '';

    # Manually build since we removed the scripts
    buildPhase = ''
      runHook preBuild
      cd src/memory
      echo "Memory tsconfig:"
      cat tsconfig.json
      npx tsc
      chmod +x dist/*.js
      cd ../..
      runHook postBuild
    '';

    # Broken symlinks to other workspaces (which are not in $out) cause build failure
    # We remove them. If runtime fails, we'll need to bundle dependencies.
    preFixup = ''
      find $out -type l ! -exec test -e {} \; -delete
    '';

    doCheck = false;
    dontNpmPrune = true;

    meta = with prev.lib; {
      description = "MCP server for persistent memory via knowledge graph";
      homepage = "https://github.com/modelcontextprotocol/servers";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
