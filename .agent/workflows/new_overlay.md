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

1. **Document**:
   Create a documentation entry.
   - Read Template: `view_file docs/Templates/Module.md` or `docs/Templates/Note.md`
   - Copy Template: `cp docs/Templates/Module.md docs/Modules/Overlays/<name>.md` (Create dir if needed)
   - Fill in details: What does this overlay modify? Why is it needed?
