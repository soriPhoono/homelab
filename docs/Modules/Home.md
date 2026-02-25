# Home Modules

Home modules define the user's software environment and personal preferences.

## 📂 Categories

### 🛠️ Core (`modules/home/core`)

The foundation of a user profile:

- **Shells**: Advanced Fish shell configuration.
- **Git**: Global git identities and signing settings.
- **SSH/Secrets**: Secure credential management via sops and agenix.

### 🚀 UserApps (`modules/home/userapps`)

End-user software and tools:

- **Browsers**: Highly configured instances of Librewolf, Firefox, Chrome and Floorp.
- **Communication**: Discord and other messaging clients.
- **Development**:
  - **Editors**: Neovim (fully IDE-capable) and Antigravity.
  - **Agents**: Gemini (with Jules CLI) and Claude.
  - **Knowledge Management**: Obsidian with specific project archival workflows.

## 🧩 Usage

Toggle features within your user's `default.nix`:

```nix
userapps.development.editors.neovim.enable = true;
userapps.development.agents.gemini.enableJules = true;
```
