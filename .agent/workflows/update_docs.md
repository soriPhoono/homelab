______________________________________________________________________

## description: Update or create documentation for an existing component

1. **Identify Component Type**:
   Determine what you are documenting:

   - **System** (Machine config): `docs/Systems/<hostname>.md`
   - **NixOS Module**: `docs/Modules/NixOS/<name>.md`
   - **Home Manager Module**: `docs/Modules/Home/<name>.md`
   - **Package**: `docs/Modules/Pkgs/<name>.md`
   - **Architecture Decision**: `docs/Architecture/Decisions/<name>.md`

1. **Read Template**:
   Read the appropriate template to understand the structure.

   - System: `docs/Templates/System.md`
   - Module: `docs/Templates/Module.md`
   - Decision: `docs/Templates/Decision.md`
   - Note: `docs/Templates/Note.md`

   ```bash
   cat docs/Templates/Module.md # Example
   ```

1. **Create/Update File**:
   Create the file in the correct directory. **Importantly**, use the template content as a base if creating a new file.

   ```bash
   # Example
   cp docs/Templates/Module.md docs/Modules/NixOS/my-module.md
   ```

1. **Populate Content**:
   Fill in the YAML frontmatter and the sections.

   - `type`: `module`, `system`, etc.
   - `status`: `wip`, `stable`
   - `tags`: Add relevant tags.

1. **Verify**:
   Ensure the file is created and contains valid markdown.
