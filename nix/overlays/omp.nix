_: _final: prev: let
  version = "15.7.5";
in {
  omp = prev.buildNpmPackage rec {
    pname = "oh-my-pi";
    inherit version;

    # The omp npm package (TypeScript source).
    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@oh-my-pi/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
      hash = "sha256-Hr5SQwxvosshGfqXZ8jzFkuisSljt1HqkbOzllc6pqY=";
    };

    # Lockfile generated from an extracted copy of the package with --include=dev.
    # Regenerate: download the tgz, tar xzf it, cd into it, npm install --package-lock-only --include=dev
    npmDepsHash = "sha256-4kf6Wdyu12V67aNk8w5/nspsVjxr1Zz1FSWaOMxRX5I=";

    prePatch = ''
      cp ${./omp-package-lock.json} package-lock.json
    '';

    npmDepsFetcherVersion = 2;
    makeCacheWritable = true;
    npmFlags = ["--ignore-scripts" "--include=dev"];
    dontNpmBuild = true;

    installPhase = ''
      mkdir -p $out/lib/omp/node_modules/@oh-my-pi/pi-coding-agent
      cp -r . $out/lib/omp/node_modules/@oh-my-pi/pi-coding-agent/

      # Bundle the bun runtime (from the omp release asset, v1.3.14+).
      # nixpkgs bun is too old (v1.3.13); omp requires >= 1.3.14.
      cp ${prev.fetchurl {
        url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
        hash = "sha256-Losyzql+Qa5Zm9P82+A0ZDwIu8ac8SX7AL6YF/+l4BU=";
      }} $out/lib/omp/bun
      chmod +x $out/lib/omp/bun

      mkdir -p $out/bin
      makeWrapper $out/lib/omp/bun $out/bin/pi \
        --add-flags "run $out/lib/omp/node_modules/@oh-my-pi/pi-coding-agent/src/cli.ts"
    '';

    meta = {
      description = "AI coding agent for the terminal — hash-anchored edits, LSP, Python, browser, subagents, and more";
      homepage = "https://omp.sh";
      license = prev.lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      maintainers = [];
    };
  };
}
