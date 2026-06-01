_: _final: prev: let
  version = "0.78.0";
  system = prev.stdenv.hostPlatform.system;

  src =
    if system == "x86_64-linux"
    then
      prev.fetchurl {
        url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-x64.tar.gz";
        hash = "sha256-isAzQ9HhIoEG6BchV/Mta4goKeRrNP6vV38XGl8Th8w=";
      }
    else if system == "aarch64-linux"
    then
      prev.fetchurl {
        url = "https://github.com/earendil-works/pi/releases/download/v${version}/pi-linux-arm64.tar.gz";
        hash = "sha256-SRVRc2gkc3INnez03uy+11T66Ekl7wA8C2aqwx1fkAU=";
      }
    else throw "pi-coding-agent: unsupported system ${system}";
in {
  pi = prev.stdenv.mkDerivation {
    pname = "pi-coding-agent";
    inherit version;

    inherit src;

    sourceRoot = "pi";

    installPhase = ''
      mkdir -p $out/bin $out/share/pi
      cp pi $out/bin/
      cp -r docs examples assets theme export-html node_modules package.json CHANGELOG.md README.md $out/share/pi/
    '';

    meta = {
      description = "Minimal terminal coding agent";
      homepage = "https://pi.dev";
      license = prev.lib.licenses.mit;
      platforms = ["x86_64-linux" "aarch64-linux"];
      maintainers = [];
    };
  };
}
