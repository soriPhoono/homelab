# Testing & Automation Roadmap

This document outlines the plan for enhancing the testing framework and automation pipelines for the `homelab` repository.

## 1. Strict Repository Structure Checks ✅ Implemented

**Goal**: Enforce a strict directory structure for home configurations to ensure clarity and modularity.

**Requirement**:

- Home configurations MUST reside in `homes/<user>/`.
- Home configurations MUST NOT reside in `homes/<user>@<system>/`.
- **Clarification**: System-specific home configurations (e.g., for `droids` or `system-manager`) should be managed within their respective system modules (`droids/` or `systemConfigs/`), NOT by creating separate top-level directories in `homes/`.

**Status**: Implemented in `tests/structure.nix`. Runs as part of `nix flake check`.

## 2. Specialized System Environments (Nix-on-Droid & System Manager)

### 2.1 Nix-on-Droid Environment Checks ✅ Implemented

**Goal**: Verify that the Nix-on-Droid configuration exports a functional and consistent environment.

**Status**: Implemented in `tests/droid-env.nix`. Checks:

- Existence of `config.build.activationPackage`.
- Key attributes in `config.environment.variables`.
- Presence of expected packages in `config.environment.systemPackages`.

Runs as part of `nix flake check`.

> **Note**: Full *builds* of Nix-on-Droid configurations require `--impure` due to `builtins.storePath` usage. See [testing.md](../testing.md) for the build command.

## 3. Future Automation (GitHub Actions)

We intend to introduce Nix-controlled GitHub Actions to automate maintenance and ensure stability.

### 3.1 Automatic Dependency Updates

**Action**: periodically update `flake.lock` and other inputs.

- **Tool**: [update-nix-fetchgit](https://github.com/nix-community/update-nix-fetchgit) or [renovate](https://github.com/renovatebot/renovate).
- **Workflow**:
  - Schedule: Weekly or Daily.
  - Create a Pull Request with updated inputs.
  - Auto-merge if CI passes (optional).

### 3.2 Automated Builds

**Action**: Build packages and system configurations on every push to `main` or Pull Requests.

- **Workflow**:
  - Trigger: `push`, `pull_request`.
  - Steps:
    - Install Nix (via `cachix/install-nix-action` or `DeterminateSystems/nix-installer-action`).
    - Check flake (`nix flake check`).
    - Build all hosts (`nix build .#nixosConfigurations.HOST.config.system.build.toplevel`).
    - Build all homes (`nix build .#homeConfigurations.USER.activationPackage`).
    - Cache results to Cachix or generic GitHub Actions cache.

## 4. Non-NixOS System Management via System Manager

**Goal**: Extend uniform configuration management to non-NixOS Linux distributions (e.g., Debian, Ubuntu servers).

**Tool**: [nix-community/system-manager](https://github.com/nix-community/system-manager)

**Plan**:

- Integrate `system-manager` as a flake input.
- Create a new top-level output group stored in `environments/`.
- Define modules that can apply system-level configuration (services, users, etc.) without replacing the host OS kernel/bootloader.
- Allow these systems to coexist with full NixOS systems in the repository.
