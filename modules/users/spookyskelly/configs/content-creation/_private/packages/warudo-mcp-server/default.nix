# warudo-mcp-server: an MCP server for Warudo. It talks to Warudo's native
# API (ws://[::1]:19053) and to the "MCP Bridge" Warudo plugin
# (ws://localhost:5678), reading both one-time tokens from Warudo's Player.log.
{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_22,
}:
buildNpmPackage rec {
  pname = "warudo-mcp-server";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "KhoaDayy";
    repo = "warudo-mcp";
    rev = "v${version}";
    hash = "sha256-XCjUXfo57N17ukE1XtzECx6UHpEYn2cAJleTLKGgIbg=";
  };

  sourceRoot = "${src.name}/mcp-server";

  # Upstream's lockfile leaves `resolved` and `integrity` out of most
  # entries, so the offline npm cache cannot be fetched from it. The vendored
  # copy pins the same versions with both fields filled in from the npm
  # registry. buildNpmPackage applies postPatch before fetching dependencies.
  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  nodejs = nodejs_22;
  npmDepsHash = "sha256-v2ADTv6DcB65zWtAOBn/JAn6TRxOQ5ob2MTCSrRQbLc=";

  meta = {
    description = "Model Context Protocol server for Warudo";
    homepage = "https://github.com/KhoaDayy/warudo-mcp";
    license = lib.licenses.mit;
    mainProgram = "warudo-mcp-server";
  };
}
