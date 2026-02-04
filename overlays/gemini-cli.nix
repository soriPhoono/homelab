_: _final: prev: {
  gemini-cli = prev.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.26.0";
    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-wvCSYr5BUS5gggTFHfG+SRvgAyRE63nYdaDwH98wurI=";
    };

    npmDepsHash = "sha256-nfmIt+wUelhz3KiW4/pp/dGE71f2jsPbxwpBRT8gtYc=";

    nodejs = prev.nodejs_22;

    nativeBuildInputs = [prev.pkg-config];
    buildInputs = [prev.libsecret];

    # Disable tests if they fail or require network
    doCheck = false;

    dontNpmPrune = true;
    dontCheckForBrokenSymlinks = true;

    postInstall = ''
      cp -r packages $out/lib/node_modules/@google/gemini-cli/
    '';

    meta = with prev.lib; {
      description = "CLI for Google Gemini";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = [];
    };
  };
}
