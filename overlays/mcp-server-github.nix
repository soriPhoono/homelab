_: _final: prev: {
  mcp-server-github = prev.buildGoModule rec {
    pname = "github-mcp-server";
    version = "0.30.3";

    src = prev.fetchFromGitHub {
      owner = "github";
      repo = "github-mcp-server";
      rev = "v${version}";
      hash = "sha256-RqTwii79h7Kk1bpJT1uGG2ODZE5DtROZZyMDKvH3jmo=";
    };

    vendorHash = "sha256-rv7mZQ2/j4R9s3p+Psq5E2I99zFtnieGc3eaMT3ykqQ=";

    nativeBuildInputs = [prev.makeWrapper];

    ldflags = [
      "-s"
      "-w"
      "-X main.version=${version}"
    ];

    doCheck = false;

    postInstall = ''
      wrapProgram $out/bin/github-mcp-server \
        --prefix PATH : ${prev.lib.makeBinPath [prev.git]}
    '';

    meta = with prev.lib; {
      description = "GitHub MCP Server — interact with GitHub via Model Context Protocol";
      homepage = "https://github.com/github/github-mcp-server";
      license = licenses.mit;
      maintainers = [];
    };
  };
}
