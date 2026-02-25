_: _final: prev: {
  jules-cli = prev.buildNpmPackage rec {
    pname = "jules-cli";
    version = "0.1.42";

    src = prev.fetchurl {
      url = "https://registry.npmjs.org/@google/jules/-/jules-${version}.tgz";
      hash = "sha256-hNhbE3dyNuSBW3h5EPS3TRlZytOzv3IvK2MG83hqD3U=";
    };

    # Since the package is just a wrapper, we can try to use a very simple lockfile
    # or skip npmDepsHash if possible (but buildNpmPackage requires it).
    # I'll use a dummy and expect the user to update it from the error log.
    npmDepsHash = "sha256-t807w3tVH3wuU7GqJZ+9pberQYrtKDpl7o6WErrjI/4=";

    dontNpmBuild = true;

    npmInstallFlags = ["--ignore-scripts"];

    # Make buildNpmPackage happy if package-lock.json is missing
    # We must provide it before npmConfigHook runs.
    postPatch = ''
      cp ${builtins.toFile "package-lock.json" (builtins.replaceStrings ["\${version}"] [version] (builtins.readFile ./package-lock.json))} package-lock.json
    '';

    nativeBuildInputs = [prev.makeWrapper];

    postInstall = ''
      wrapProgram $out/bin/jules \
        --prefix PATH : ${prev.lib.makeBinPath [prev.nodejs]}
    '';

    meta = {
      description = "Jules CLI - Asynchronous coding agent from Google";
      homepage = "https://jules.google";
      license = prev.lib.licenses.unfree;
      mainProgram = "jules";
    };
  };
}
