# Custom Packages

This directory contains custom package declarations that are automatically exported as flake `packages`. Packages defined here are available for building and installation across all system and home configurations.

## Export Mechanism

The flake-parts framework exports all derivations found in this directory as `packages.<system>.*`. Any `.nix` file or directory with a `default.nix` will be evaluated and its resulting derivation made available as a flake output.

**Access pattern:**

```bash
nix build .#<package-name>
nix shell .#<package-name>
```

## Current State

This directory is currently unpopulated. Custom packages should be added here when:

- A package does not exist in nixpkgs and requires a custom derivation
- An existing nixpkgs package requires significant patching that warrants a separate derivation
- A proprietary or internal tool needs to be distributed across all hosts

## Adding a Package

1. Create a `.nix` file or directory with `default.nix` in this directory
1. Define a standard Nix derivation or use `pkgs.callPackage`
1. The package is automatically exported — no manual registration required

**Example:**

```nix
{ pkgs, ... }:

pkgs.stdenv.mkDerivation rec {
  pname = "my-tool";
  version = "1.0.0";

  src = ./src;

  buildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${pkgs.python3}/bin/python3 $out/bin/my-tool \
      --add-flags "$src/main.py"
  '';
}
```

## Relationship to Overlays

Use **overlays** (`nix/overlays/`) when modifying or extending existing packages in the global `pkgs` set. Use **this directory** (`nix/pkgs/`) when defining entirely new packages that do not modify existing nixpkgs derivations.
