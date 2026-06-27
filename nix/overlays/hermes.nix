{inputs, ...}: _final: prev: let
  inherit (prev.stdenv.hostPlatform) system;
  origHermes = inputs.hermes-agent.packages.${system}.full;
  origVenv = origHermes.passthru.hermesVenv;

  # The root cause: `hermes gateway` (bare, no subcommand) triggers
  # ModuleNotFoundError for cron.scheduler_provider because the cron
  # package isn't pre-cached by _prepare_agent_startup (which only runs
  # for `gateway run`, not bare `gateway`).  The same shadowing happens
  # for the web server / desktop when plugins/cron is on sys.path.
  #
  # Fix: create a tiny Python shim that imports cron first, then delegates
  # to the real hermes CLI.  This avoids modifying the venv at all.
  siteRel = "/lib/python3.12/site-packages";
  origPython = "${origVenv}/bin/python3";

  patchedHermes =
    prev.runCommand "hermes-agent-0.17.0" {
      nativeBuildInputs = [prev.makeWrapper];
      buildInputs = [origHermes];
      inherit origPython origVenv siteRel;
    } ''
          mkdir -p $out/bin

          cat > $out/bin/_hermes_shim.py << SHIMEOF
      import sys
      import os
      import cron  # noqa: F401
      sys.path.insert(0, os.environ.get('_HERMES_REAL_SITE', ""))
      from hermes_cli.main import main
      sys.exit(main())
      SHIMEOF

          for prog in hermes hermes-agent hermes-acp; do
            if [ -f "${origHermes}/bin/$prog" ]; then
              makeWrapper "${origPython}" "$out/bin/$prog" \
                --set _HERMES_REAL_SITE "${origVenv}${siteRel}" \
                --add-flags "$out/bin/_hermes_shim.py" \
                --suffix PATH : "${origHermes}/bin"
            fi
          done

          if [ -d "${origHermes}/share" ]; then
            cp -r "${origHermes}/share" "$out/share"
          fi
    '';
in {
  hermes-desktop =
    prev.runCommand "hermes-desktop-0.15.1" {
      nativeBuildInputs = [prev.makeWrapper];
      buildInputs = [inputs.hermes-agent.packages.${system}.desktop];
      inherit patchedHermes;
    } ''
      mkdir -p $out/bin
      # Copy the original desktop wrapper script but patch its
      # HERMES_DESKTOP_HERMES to point at our shimmed hermes.
      # Must NOT use --set (makeWrapper) because the inner script's
      # own `export HERMES_DESKTOP_HERMES=...` overrides it.
      sed 's|/nix/store/[a-z0-9]\+-hermes-agent-[^/]*/bin/hermes|${patchedHermes}/bin/hermes|g' \
        "${inputs.hermes-agent.packages.${system}.desktop}/bin/hermes-desktop" > "$out/bin/hermes-desktop"
      chmod +x "$out/bin/hermes-desktop"
      if [ -d "${inputs.hermes-agent.packages.${system}.desktop}/share" ]; then
        mkdir -p $out/share
        cp -r "${inputs.hermes-agent.packages.${system}.desktop}/share"/* "$out/share/" 2>/dev/null || true
      fi
    '';
  hermes-full = patchedHermes;
}
