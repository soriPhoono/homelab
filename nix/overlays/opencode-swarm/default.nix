_: _final: prev: let
  version = "0.63.2";

  tarball = prev.fetchurl {
    url = "https://registry.npmjs.org/opencode-swarm-plugin/-/opencode-swarm-plugin-${version}.tgz";
    hash = "sha256-ZWop4tjcBZrzpq0WPO+JXixv0gzlttB2nhQk9+Ap3T8=";
  };

  lockfile = builtins.toFile "package-lock.json" (builtins.readFile ./lockfile.json);

  srcWithLock = prev.runCommand "opencode-swarm-plugin-src" {} ''
    tar xzf ${tarball}
    cp ${lockfile} package/package-lock.json
    mv package $out
  '';
in {
  opencode-swarm-plugin = prev.buildNpmPackage {
    pname = "opencode-swarm-plugin";
    inherit version srcWithLock;
    src = srcWithLock;

    npmDeps = prev.fetchNpmDeps {
      src = srcWithLock;
      hash = "sha256-fifYQJSzw7iJJiKcSRMDMXTt/2qvhUgAPaX5bw0fe/M=";
    };

    buildPhase = ''
      runHook preBuild
      runHook postBuild
    '';

    nativeBuildInputs = [prev.makeWrapper prev.bun];

    installPhase = let
      pkgDir = "$out/lib/node_modules/opencode-swarm-plugin";
    in ''
      mkdir -p ${pkgDir}
      cp -r . ${pkgDir}/

      mkdir -p $out/bin
      makeWrapper ${prev.bun}/bin/bun $out/bin/swarm \
        --add-flags "${pkgDir}/dist/bin/swarm.js" \
        --set-default NODE_ENV production \
        --prefix PATH : ${prev.bun}/bin
    '';

    meta = with prev.lib; {
      description = "Multi-agent swarm coordination for OpenCode with learning capabilities, beads integration, and Agent Mail";
      homepage = "https://github.com/joelhooks/swarm-tools";
      license = licenses.mit;
      maintainers = [];
      platforms = platforms.linux;
    };
  };
}
