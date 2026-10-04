# OpenRig is not in nixpkgs. The npm tarball ships prebuilt dist/ output
# but no lockfile, so package-lock.json alongside this file is generated
# from it (devDependencies and the postinstall ABI check stripped):
#
#   jq 'del(.devDependencies) | del(.scripts.postinstall)' package.json
#   npm install --package-lock-only --ignore-scripts
#
# Regenerate it whenever `version` changes.
{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  nodejs_22,
  tmux,
}:
buildNpmPackage (finalAttrs: {
  pname = "openrig";
  version = "0.6.4";

  src = fetchurl {
    url = "https://registry.npmjs.org/@openrig/cli/-/cli-${finalAttrs.version}.tgz";
    hash = "sha512-AUS+4rUV69I9GLDuPRAcoi+CuFSbZNK4m4R2NxUwjUTx6GUFCUjMDBp/uiDX1f7s5TNc9ZgxVwczlMGNDnB0zw==";
  };

  # Upstream supports Node 22 and 24 only; better-sqlite3 segfaults on 20.
  nodejs = nodejs_22;

  npmDepsHash = "sha256-KVcBEguWQLss3GlgL9FA+9rnLeD5U2SvJZjjQfrt5pA=";

  postPatch = ''
    ${lib.getExe jq} 'del(.devDependencies) | del(.scripts.postinstall)' \
      package.json > package.json.new
    mv package.json.new package.json
    cp ${./package-lock.json} package-lock.json
  '';

  # dist/ is already built in the published tarball, and better-sqlite3
  # ships N-API prebuilds for linux-x64/arm64, so nothing compiles here.
  dontNpmBuild = true;

  # Every rig seat is a tmux session.
  postFixup = ''
    for bin in $out/bin/*; do
      wrapProgram "$bin" --prefix PATH : ${lib.makeBinPath [ tmux ]}
    done
  '';

  meta = {
    description = "Multi-agent harness running Claude Code and Codex as persistent tmux-backed teams";
    homepage = "https://github.com/mvschwarz/openrig";
    license = lib.licenses.asl20;
    mainProgram = "rig";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
})
