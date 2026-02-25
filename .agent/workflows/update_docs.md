______________________________________________________________________

## description:

______________________________________________________________________

## description: Update or create documentation for an existing component

1. **Identify Component Type**:
   Determine what you are documenting:

   - **Library** (Internal helper functions): `docs/Library.md`
   - **System** (Machine config): `docs/Systems/<hostname>.md`
   - **Droid** (Android NixOnDroid config): `docs/Droids/<username>.md`
   - **Environments** (System-manager controlled environment config): `docs/Environments/<hostname>.md`
   - **Homes** (Home manager config): `docs/Homes/<username>.md`
   - **NixOS Module**: `docs/Modules/NixOS/<name>.md`
   - **Droid Module**: `docs/Modules/Droid/<name>.md`
   - **Home Manager Module**: `docs/Modules/Home/<name>.md`
   - **Overlays**: `docs/Overlays/<name>.md`
   - **Package**: `docs/Modules/Pkgs/<name>.md`
   - **Templates**: `docs/Templates/<name>.md`

1. **Read Index**:
   Read the appropriate index to understand the structure of the item you're working with.

   ```bash
   cat docs/<subpath>/00_index.md # Example
   ```

1. **Create/Update File**:
   Create the file in the correct directory.

   ```bash
   # Example
   touch docs/<subpath>/<filename>.md
   ```

1. **Populate Content**:
   Fill in the YAML frontmatter and the sections.

   - `type`: `module`, `system`, etc.
   - `status`: `wip`, `stable`
   - `tags`: Add relevant tags.

1. **Verify**:
   Ensure the file is created and contains valid markdown.
