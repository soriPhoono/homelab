______________________________________________________________________

## description: Create a new package overlay

1. **File Creation**:
   Create `overlays/<name>.nix`.

1. **Content**:

   ```nix
   { lib, self, ... }:
   final: prev: {
     # Example: Override a package version
     # hello = prev.hello.overrideAttrs (old: {
     #   src = ...;
     # });
   }
   ```

1. **Auto-Discovery**:
   `overlays/default.nix` automatically picks up any `.nix` file in the directory.
