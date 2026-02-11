_: _final: prev: {
  gemini-cli = prev.buildNpmPackage rec {
    pname = "gemini-cli";
    version = "0.28.1";
    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-wvCSYr5BUS5gggTFHfG+SRvgAyRE63nYdaDwH98wurI=";
    };

    npmDepsHash = "sha256-nfmIt+wUelhz3KiW4/pp/dGE71f2jsPbxwpBRT8gtYc=";

    nodejs = prev.nodejs_22;

    nativeBuildInputs = [prev.pkg-config prev.makeWrapper];
    buildInputs = [prev.libsecret];

    # Disable tests if they fail or require network
    doCheck = false;

    dontNpmPrune = true;
    dontCheckForBrokenSymlinks = true;

    postInstall = ''
      cp -r packages $out/lib/node_modules/@google/gemini-cli/

      # Wrap with runtime dependencies for MCP server support
      wrapProgram $out/bin/gemini \
        --prefix PATH : ${prev.lib.makeBinPath [
        prev.nodejs_22 # node/npx for dynamic MCP imports
        prev.git # VCS operations (server-git, server-github)
        prev.curl # HTTP fetching (server-fetch)
        prev.google-chrome # Puppeteer/Mermaid rendering
        prev.nodePackages.mermaid-cli # mmdc for diagram rendering
      ]} \
        --set PUPPETEER_EXECUTABLE_PATH "${prev.google-chrome}/bin/google-chrome"
    '';

    meta = with prev.lib; {
      description = "CLI for Google Gemini";
      homepage = "https://github.com/google-gemini/gemini-cli";
      license = licenses.asl20;
      maintainers = [];
    };
  };
}
