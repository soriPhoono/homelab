---
description: Create a new flake template
---

1.  **Create Directory**:
    ```bash
    mkdir -p templates/<name>
    ```

2.  **Meta Data**:
    Create `templates/<name>/meta.json`.
    ```json
    {
      "description": "Description of what this template provides"
    }
    ```

3.  **Flake Content**:
    Add the `default.nix` (which is effectively the `flake.nix` content of the template, or the files to be copied).
    *Note: Flake templates usually contain a `flake.nix` and other files. The `flake.nix` discovery logic maps `path = ./templates/<name>`. Meaning the directory itself is the template.*

4.  **Verify**:
    Check if it appears in:
    ```bash
    nix flake show
    ```
