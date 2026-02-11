______________________________________________________________________

## description:

______________________________________________________________________

## description: Create a new flake template

1. **Create Directory**:

   ```bash
   mkdir -p templates/<name>
   ```

1. **Meta Data**:
   Create `templates/<name>/meta.json`.

   ```json
   {
     "description": "Description of what this template provides"
   }
   ```

1. **Flake Content**:
   Add the `default.nix` (which is effectively the `flake.nix` content of the template, or the files to be copied).
   *Note: Flake templates usually contain a `flake.nix` and other files. The `flake.nix` discovery logic maps `path = ./templates/<name>`. Meaning the directory itself is the template.*

1. **Verify**:
   Check if it appears in:

   ```bash
   nix flake show
   ```

1. **Document**:
   Update Contributing docs or add a note.

   - Update `docs/Meta/CONTRIBUTING.md` if this is a major development template.
   - Or create `docs/Modules/Templates/<name>.md` if extensive documentation is needed.
