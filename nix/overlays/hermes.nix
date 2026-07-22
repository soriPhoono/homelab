{inputs, ...}: final: prev: let
  inherit (prev.stdenv.hostPlatform) system;
  origHermes = inputs.hermes-agent.packages.${system}.default;
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

  patchedDesktop = final.callPackage "${inputs.hermes-agent}/nix/desktop.nix" {
    hermesNpmLib = origHermes.passthru.hermesNpmLib;
    inherit (final) electron;
    hermesAgent = patchedHermes;
  };
in {
  fetchurl = args:
    if args ? url && args.url == "https://artifacts.electronjs.org/headers/dist/v41.9.1/node-v41.9.1-headers.tar.gz"
    then prev.fetchurl (args // {sha256 = "sha256-zOl8rx6woWh7aeRUOlkTMviKc/EAQQX6nr/MxAx1ZPI=";})
    else prev.fetchurl args;

  hermes-desktop = patchedDesktop;
  hermes = patchedHermes;
}
