# Secret Management Spec

This repository integrates `sops-nix` and `agenix` to provide robust, encrypted secret management across NixOS systems and user environments.

## `sops-nix` Integration

Used for most system and application-level secrets.

- **Configuration**: Managed via `.sops.yaml` in the repository root.
- **Key Storage**: Uses `age` keys for encryption/decryption.
- **Usage**:
  - `secrets/`: Shared or global secrets.
  - `nix/systems/<host>/secrets.yaml`: Machine-specific secrets.
  - `nix/homes/<user>/secrets.yaml`: User-specific secrets.

The flake automatically imports `sops-nix.nixosModules.sops` into all systems and `sops-nix.homeManagerModules.sops` into all Home Manager configurations.

## `agenix` Integration

Used primarily for development shell secrets via `agenix-shell`.

- **Configuration**: Defined in `secrets.nix` in the repository root.
- **Usage**: Encrypted secrets are used to provide environment variables (like API keys) to the `nix develop` shell without exposing them in the codebase.

## Security Best Practices

- **Pre-commit Hooks**: `gitleaks` is used to prevent accidental commits of plaintext secrets.
- **No Private Keys**: Private `age` or SSH keys used for decryption are never committed to the repository.
- **Surgical Access**: Secrets are only decrypted on-demand and provided to the services or users that need them.
