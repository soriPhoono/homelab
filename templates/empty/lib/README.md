# Library Functions

This directory contains utility functions used throughout the flake configuration. These functions extend the standard `nixpkgs` library.

## Usage

These functions are typically passed to modules via `lib` or `extraSpecialArgs`.

## Structure

- `default.nix`: Entry point, importing and merging other library files.
- `module-utils.nix`: Utilities for module system manipulation.
- `file-utils.nix`: Utilities for file handling (like `scanPaths`).
