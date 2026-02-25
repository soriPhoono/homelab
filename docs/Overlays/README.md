# Overlays

Overlays allow us to extend and modify the global package set provided by nixpkgs.

## 📂 Custom Overlays

- **[gemini-cli-with-jules.nix](../../overlays/gemini-cli-with-jules.nix)**: Wraps `gemini-cli` with a private `jules-cli` dependency.
- **[antigravity.nix](../../overlays/antigravity.nix)**: Extensions for the Antigravity agentic environment.
- **[librewolf.nix](../../overlays/librewolf.nix)**: Custom configurations for the Librewolf browser.

## ⚙️ External Overlays

We also import several popular community overlays:

- **NUR**: The Nix User Repository.
- **nvf**: Neovim configuration framework.

Overlays are centrally managed in `overlays/default.nix` and automatically applied to all systems and home configurations via the flake.
