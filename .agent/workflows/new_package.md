---
description: Create a new custom package
---

1.  **Create Directory**:
    ```bash
    mkdir -p pkgs/<name>
    ```

2.  **Create Expression**:
    Create `pkgs/<name>/default.nix`.
    ```nix
    {
      lib,
      stdenv,
      fetchFromGitHub,
      ...
    }:
    stdenv.mkDerivation rec {
      pname = "<name>";
      version = "0.0.1";

      src = fetchFromGitHub {
        owner = "<owner>";
        repo = "<repo>";
        rev = "v${version}";
        hash = lib.fakeHash;
      };

      # ... build inputs and phases
    }
    ```

3.  **Auto-Discovery**:
    `pkgs/default.nix` uses `builtins.readDir`, so no manual registration is required.

4.  **Build**:
    Test the build:
    ```bash
    nix build .#<name>
    ```
