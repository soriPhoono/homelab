---
description: Create a new NixOS system configuration
---

1.  **Create Directory**: 
    Create a new directory in `systems/` matching the hostname.
    ```bash
    mkdir -p systems/<hostname>
    ```

2.  **Create Meta File**:
    Create `systems/<hostname>/meta.json` to define the architecture.
    ```json
    {
      "system": "x86_64-linux"
    }
    ```
    *(Adjust "system" if deploying to a Raspberry Pi: "aarch64-linux")*

3.  **Create Default Config**:
    Create `systems/<hostname>/default.nix`.
    ```nix
    {
      pkgs,
      lib,
      config,
      ...
    }: {
      imports = [
        # Include hardware config if available, or generate it
        # ./hardware-configuration.nix
      ];

      # Basic Network Config
      networking.hostName = "<hostname>";

      # Enable core modules
      # modules.nixos.core.enable = true; 

      system.stateVersion = "24.11";
    }
    ```

4.  **Register**:
    No manual registration needed. `flake.nix` will automatically pick it up.

5.  **Check**:
    Run `nix flake check` to verify.
