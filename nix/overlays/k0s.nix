_: _final: prev: let
  version = "1.30.2+k0s.0";
  system = prev.stdenv.hostPlatform.system;

  src =
    if system == "x86_64-linux"
    then
      prev.fetchurl {
        url = "https://github.com/k0sproject/k0s/releases/download/v${version}/k0s-v${version}-amd64";
        hash = "sha256-m8FIjf3jxgsfJVmaobiFYxSVqu/yr+hKOhYU30KUJb8=";
      }
    else if system == "aarch64-linux"
    then
      prev.fetchurl {
        url = "https://github.com/k0sproject/k0s/releases/download/v${version}/k0s-v${version}-arm64";
        hash = "sha256-GlVaWZ4JNcO5cuAixw2YGTBd9YH0uymR5N+95fZA0nY=";
      }
    else throw "k0s: unsupported system ${system}";
in {
  k0s = prev.stdenv.mkDerivation {
    pname = "k0s";
    inherit version;

    inherit src;

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/k0s
      chmod +x $out/bin/k0s
    '';

    meta = {
      description = "Zero Friction Kubernetes";
      homepage = "https://k0sproject.io";
      license = prev.lib.licenses.asl20;
      platforms = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maintainers = [];
    };
  };
}
