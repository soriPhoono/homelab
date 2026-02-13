# Custom Packages

This directory contains custom Nix packages that are not available in upstream Nixpkgs or need significant modification.

## Adding a Package

1. Create a directory for your package (e.g., `pkgs/my-package`).
1. Create a `default.nix` containing the derivation.
1. Add it to `pkgs/default.nix` (if not using auto-discovery for packages, typically packages are manually exposed in the overlay or packages set).

## Structure

Packages here are typically exposed via the `packages` output of the flake and also added to the `pkgs` set via an overlay.
