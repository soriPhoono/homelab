_: _final: prev: let
  version = "0.3.3";

  src = prev.fetchurl {
    url = "https://github.com/ComposioHQ/composio/releases/download/%40composio%2Fcli%40${version}/composio-linux-x64.zip";
    hash = "sha256-0yXXptYnxuZe88DppFhVSfr92/q4SqE5SXP07vomNIk=";
  };
in {
  composio = prev.stdenv.mkDerivation {
    pname = "composio";
    inherit version;

    inherit src;

    nativeBuildInputs = [prev.unzip prev.autoPatchelfHook];
    buildInputs = [prev.stdenv.cc.cc.lib prev.zlib prev.openssl];

    sourceRoot = ".";
    dontConfigure = true;
    dontBuild = true;
    dontStrip = true; # 320MB Bun-compiled binary

    unpackPhase = ''
      runHook preUnpack
      unzip -q $src
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/composio $out/bin
      cp -Rp composio-linux-x64/. $out/lib/composio/
      chmod +x $out/lib/composio/composio
      ln -s $out/lib/composio/composio $out/bin/composio
      runHook postInstall
    '';

    meta = with prev.lib; {
      description = "Composio CLI — search, execute, and script tools from your shell";
      homepage = "https://docs.composio.dev/docs/cli";
      license = licenses.mit;
      platforms = ["x86_64-linux"];
      mainProgram = "composio";
    };
  };
}
