{flakePath}: let
  flake = builtins.getFlake flakePath;
  inherit (flake.inputs.nixpkgs-weekly) lib;
  pkgs = flake.inputs.nixpkgs-weekly.legacyPackages.x86_64-linux;

  droidConfigs = flake.nixOnDroidConfigurations or {};

  # Evaluate config metadata only — no aarch64 builds needed
  report = lib.concatStringsSep "\n" (lib.mapAttrsToList (name: config: let
      hasActivation = config ? activationPackage || config.config.build ? activationPackage;
      hmEnabled = config.config.home-manager.useGlobalPkgs or false;
      system = config.pkgs.stdenv.hostPlatform.system
      or config.config.nixpkgs.hostPlatform.system
      or (config.config.build.system or "aarch64-linux");
    in ''
      [droid/${name}]
        system:      ${system}
        activation:  ${
        if hasActivation
        then "✓"
        else "✗ MISSING"
      }
        home-manager: ${
        if hmEnabled
        then "✓ useGlobalPkgs=true"
        else "✗ not enabled"
      }
    '')
    droidConfigs);
  # Chain evaluations sequentially using an accumulator that builds on previous results
  # Note: Since this is mostly evaluation-heavy, we force a dependency chain
  # by having each subsequent check "wait" for the previous one to complete
  # via a shared report or sequential derivation triggers.

  # Group configs and build a report derivation that depends on each sequentially
  droidList = lib.mapAttrsToList (name: config: {inherit name config;}) droidConfigs;

  sequentialEval =
    lib.foldl (acc: item: let
      prev = acc.last or null;
      evalDerivation =
        pkgs.runCommand "eval-droid-${item.name}" {
          prev = lib.optionalString (prev != null) prev;
        } ''
          echo "Evaluating droid/${item.name}..."
          # Force evaluation of activation package and other key attributes
          echo "${item.config.activationPackage or "no-activation"}" > /dev/null
          echo "${item.name} evaluated" > $out
        '';
    in {
      last = evalDerivation;
      list = acc.list ++ [evalDerivation];
    }) {
      last = null;
      list = [];
    }
    droidList;
in
  if (droidConfigs == {})
  then
    pkgs.runCommand "droid-eval-skip" {} ''
      echo "No Nix-on-Droid configurations found. Skipping."
      touch $out
    ''
  else
    pkgs.runCommand "droid-eval" {
      passAsFile = ["report"];
      # Depend on all sequential evals to force ordering
      buildInputs = sequentialEval.list;
      report = ''
        Nix-on-Droid evaluation report
        ================================
        ${report}
        ================================
        All ${toString (builtins.length (builtins.attrNames droidConfigs))} configuration(s) evaluated successfully.
      '';
    } ''
      cat "$reportPath"
      cp "$reportPath" $out
    ''
