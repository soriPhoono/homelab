# Template Checks System

This directory contains the unit tests and checks for the template. The system is designed to be dynamic, scalable, and built on top of [nixtest](https://github.com/jetify-com/nixtest).

## Architecture

The checks system operates via a discovery mechanism defined in `lib/default.nix`.

### Dynamic Discovery

In the `flake.nix`, the `checks` attribute is populated by calling `lib.discoverTests`:

```nix
checks = let
  unitTests = lib.discoverTests {
    inherit pkgs inputs self;
    inherit (inputs) nixtest;
  } ./tests;
in
  unitTests;
```

`lib.discoverTests` performs the following actions:

1. **Scans**: It looks for all `.nix` files within this directory (`./tests`).
1. **Imports**: It imports each found file.
1. **Applies**: It calls the imported function with a set of arguments (including `pkgs`, `inputs`, `self`, and `lib`).

### Test Format

Each test file in this directory should export a function that accepts an attribute set of dependencies and returns a check (usually a `nixtest` derivation).

Example test structure:

```nix
{ pkgs, nixtest, lib, ... }:

nixtest.lib.mkTest {
  inherit pkgs;
  name = "example-test";
  tests = {
    test_equality = {
      expected = 1;
      expr = 1;
    };
  };
}
```

## Running Tests

Tests are automatically integrated into standard Nix flake checks. You can run them using:

```bash
nix flake check
```

Or run specific checks via:

```bash
nix build .#checks.x86_64-linux.YOUR_TEST_NAME
```

## Key Components

- **`lib.discoverTests`**: The engine that finds and evaluates test files.
- **`nixtest`**: The unit testing framework providing assertion and test suite builders.
- **`flake-parts`**: Orchestrates the per-system evaluation of checks.
