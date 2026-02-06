---
description: Create a new Home Manager configuration
---

1.  **Identify Target**:
    Determine if this is for a specific user on a specific host (`user@host`) or a generic user config (`user`).

2.  **Create Directory**:
    ```bash
    mkdir -p homes/<user>@<host>
    # OR
    mkdir -p homes/<user>
    ```

3.  **Create Meta File**:
    Create `homes/<target>/meta.json`.
    ```json
    {
      "system": "x86_64-linux"
    }
    ```

4.  **Create Default Config**:
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

5.  **Validate**:
    `nix flake check`
