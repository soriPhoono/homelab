# Wraps an OpenCode package: Node and Python on PATH for the agent's tools,
# and Claude Code's config left alone.
#
# OpenCode Desktop runs a bundled copy of the CLI as its backend, which cannot
# be wrapped without rebuilding the app, so the desktop app is wrapped instead.
# At start it replaces its environment with `$SHELL -il -c 'env -0'`, run from
# this one. That keeps both settings because fish keeps an inherited PATH, and
# the NixOS and home-manager session scripts do not re-export PATH when their
# guard variables are already set, as they are in a graphical session.
{ lib, pkgs }:
agent:
pkgs.symlinkJoin {
  inherit (agent) pname version meta;
  name = "${agent.pname}-wrapped-${agent.version}";

  paths = [ agent ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    for bin in $out/bin/*; do
      if [ -f "$bin" ] && [ -x "$bin" ]; then
        wrapProgram "$bin" \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.nodejs
              pkgs.python3
            ]
          } \
          --run 'export OPENCODE_DISABLE_CLAUDE_CODE=1'
      fi
    done
  '';
}
