______________________________________________________________________

## description: Create a new Home Manager configuration

1. **Identify Target**:
   Determine if this is for a specific user on a specific host (`user@host`) or a generic user config (`user`).

1. **Create Directory**:

   ```bash
   mkdir -p homes/<user>@<host>
   # OR
   mkdir -p homes/<user>
   ```

1. **Create Meta File**:
   Create `homes/<target>/meta.json`.

   ```json
   {
     "system": "x86_64-linux"
   }
   ```

1. **Create Default Config**:
   Create `homes/<target>/default.nix`.

   ```nix
   {
     pkgs,
     lib,
     config,
     ...
   }: {
     imports = [
       # Import user modules
     ];

     home.username = "<user>";
     home.homeDirectory = "/home/<user>";

     system.stateVersion = "24.11";
   }
   ```

1. **Validate**:
   `nix flake check`

1. **Document**:
   Create a documentation entry for this new home configuration.
   - Read Template: `view_file docs/Templates/System.md` (Use System template or create a specific Home template if needed, System is closest for a full home config, or use Note). *Actually, for a user home, it might be better to treat it as a System or just listed in `docs/Systems` or a new `docs/Homes` if preferred. Let's use `docs/Systems/<user>@<host>.md` or `docs/Modules/Home/<user>.md`.*
   - **Decision**: Create `docs/Systems/<user>@<host>.md` or similar to track the user deployment.
   - Run: `cp docs/Templates/System.md docs/Systems/<user>-<host>.md`
   - Edit the file to reflect it is a Home Manager configuration.
