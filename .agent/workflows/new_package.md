______________________________________________________________________

## description: Create a new custom package

1. **Create Directory**:

   ```bash
   mkdir -p pkgs/<name>
   ```

1. **Create Expression**:
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

1. **Auto-Discovery**:
   `pkgs/default.nix` uses `builtins.readDir`, so no manual registration is required.

1. **Build**:
   Test the build:

   ```bash
   nix build .#<name>
   ```

1. **Document**:
   Create a documentation entry.

   - Read Template: `view_file docs/Templates/Module.md`
   - Copy Template: `cp docs/Templates/Module.md docs/Modules/Pkgs/<name>.md` (Create Pkgs directory if missing `mkdir -p docs/Modules/Pkgs`)
   - Fill in details: Version, Source, Usage.
