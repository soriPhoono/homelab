_: _final: prev: {
  mcp-server-filesystem = prev.buildNpmPackage rec {
    pname = "mcp-server-filesystem";
    version = "2026.1.14";

    src = prev.fetchFromGitHub {
      owner = "modelcontextprotocol";
      repo = "servers";
      rev = version;
      hash = "sha256-KL2YmxcXAVvGFuaaWQUOrbBl1JoZMtiGbjcxnFnMV8c=";
    };

    npmWorkspace = "src/filesystem";

    # Will need re-hash due to postPatch changes
    npmDepsHash = "sha256-NgRIzWZbXhfQp+1e9XUdh5/OlziVCBHH39paTaiQOKg=";

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
      cd src/filesystem
      echo "Listing src/filesystem:"
      ls -F
      echo "Content of package.json:"
      cat package.json
      echo "Content of tsconfig.json:"
      cat tsconfig.json
      echo "Running tsc --showConfig..."
      npx tsc --showConfig || echo "showConfig failed"
      echo "Running tsc (attempt 1)..."
      npx tsc || echo "TSC FAILED"
      ls -R dist || echo "No dist found"
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
      description = "MCP server for filesystem access";
      homepage = "https://github.com/modelcontextprotocol/servers";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
