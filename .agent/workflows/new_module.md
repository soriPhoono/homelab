______________________________________________________________________

## description: Create a new NixOS or Home Manager module

1. **Determine Scope**:

   - System-level: `modules/nixos/<name>`
   - User-level: `modules/home/<name>`

1. **Create Directory & File**:

   ```bash
   mkdir -p modules/nixos/<name>
   touch modules/nixos/<name>/default.nix
   ```

1. **Implement Standard Pattern**:
   Use the `lib.mkEnableOption` pattern.

   ```nix
   {
     options,
     config,
     lib,
     pkgs,
     ...
   }:
   with lib;
   let
     cfg = config.modules.nixos.<name>; # Adjust path accordingly
   in {
     options.modules.nixos.<name> = {
       enable = mkEnableOption "Enable <name> module";
     };

     config = mkIf cfg.enable {
       # Implementation
     };
   }
   ```

1. **Auto-Import**:
   The `modules/nixos/default.nix` (or `pkgs` equivalent) usually auto-imports these. *Verify if manual import is needed in `modules/nixos/default.nix` if it's not using discovery.*

   *(Self-Correction: `modules` directories in this repo often utilize `default.nix` that manually imports children or uses discovery. Check `modules/nixos/default.nix` to be sure. If it uses `readDir`, nothing else needed.)*

1. **Document**:
   Create a documentation entry.
   - Read Template: `view_file docs/Templates/Module.md`
   - Copy Template: `cp docs/Templates/Module.md docs/Modules/NixOS/<name>.md` (or `docs/Modules/Home/<name>.md`)
   - Fill in details: Description, Options, Dependencies.
