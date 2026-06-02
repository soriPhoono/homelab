_: _final: prev: let
  version = "15.7.5";
in {
  omp = prev.stdenv.mkDerivation {
    pname = "oh-my-pi";
    inherit version;

    src = prev.fetchurl {
      url = "https://github.com/can1357/oh-my-pi/releases/download/v${version}/omp-linux-x64";
      hash = "sha256-Losyzql+Qa5Zm9P82+A0ZDwIu8ac8SX7AL6YF/+l4BU=";
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/omp
      chmod +x $out/bin/omp
    '';

    meta = {
      description = "AI coding agent for the terminal — hash-anchored edits, LSP, Python, browser, subagents, and more";
      homepage = "https://omp.sh";
      license = prev.lib.licenses.mit;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maintainers = [];
    };
  };
}
