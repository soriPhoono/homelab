final: prev: {
  jules-cli = prev.buildNpmPackage {
    pname = "jules-cli";
    version = "0.0.1";

    src = prev.fetchNpm {
      packageName = "@google/jules"; # TODO: Verify exact package name
      version = "0.0.1"; # TODO: Update to latest version
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update hash
    };

    npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # TODO: Update hash

    dontNpmBuild = true;

    meta = {
      description = "Jules CLI";
      homepage = "https://jules.google/docs/cli/reference/";
      license = final.lib.licenses.unfree; # TODO: Verify license
    };
  };
}
