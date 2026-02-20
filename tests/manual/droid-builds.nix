{flakePath}: let
  flake = builtins.getFlake flakePath;
  inherit (flake.inputs.nixpkgs) lib;
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;

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
