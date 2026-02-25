# Product Guidelines

## Core Principles

- **Declarative Excellence**: Every system state must be defined in code. Avoid imperative "fixes" or manual configurations that aren't captured in the repository.
- **Reproducibility**: Configurations should be hermetic. A system built today should be identical to one built tomorrow from the same commit.
- **Security by Design**: Secrets must never be stored in plaintext. Use the integrated `agenix` or `sops-nix` workflows for all sensitive data.

## Implementation Standards

- **Modular Logic**: Group related configurations into modules (e.g., `modules/nixos/core`, `modules/home/userapps`). Prefer small, focused modules over monolithic files.
- **Dynamic Discovery**: Maintain the "discovery" pattern established in `flake.nix`. New systems or users should be picked up automatically by following the folder structure conventions.
- **Documentation through Code**: Use clear variable names and comments that explain *why* a certain configuration exists, especially when overriding defaults or handling hardware quirks.

## User Experience (Internal)

- **Single Command Workflows**: Common tasks (build, check, deploy) should be accessible via simple, documented commands or dev shell aliases.
- **Fail Fast**: Use `nix flake check` and pre-commit hooks to catch configuration errors before deployment.
