# Testing & Automation Roadmap

This document outlines the plan for enhancing the testing framework and automation pipelines for the `homelab` repository.

## 1. Strict Repository Structure Checks

**Goal**: Enforce a strict directory structure for home configurations to ensure clarity and modularity.

**Requirement**:

- Home configurations MUST reside in `homes/<user>/`.
- Home configurations MUST NOT reside in `homes/<user>@<system>/`.
- **Clarification**: System-specific home configurations (e.g., for `droids` or `system-manager`) should be managed within their respective system modules (`droids/` or `systemConfigs/`), NOT by creating separate top-level directories in `homes/`.

**Implementation Plan**:

- Create a new test suite (e.g., `tests/structure.nix`) using the `nixtest` framework.
- The test will walk the `homes/` directory.
- It will assert that no directory name contains the `@` character.
- **Fail Condition**: Presence of any `homes/*@*` directory.

## 2. Specialized System Environments (Nix-on-Droid & System Manager)

**Goal**: Verify that non-NixOS but system-managed environments (`nix-on-droid` and `system-manager`) export a functional and consistent environment.

**Context**: These systems are distinct from standard NixOS but are still considered "systems" with their own configuration nuances (e.g., restricted `config` options outside of Home Manager).

### 2.1 Nix-on-Droid Environment Checks

**Requirement**:

- Ensure critical environment variables (e.g., `PATH`, `SHELL`, `TERM`) are correctly set.
- specific packages expected in the Android environment are present.

**Implementation Plan**:

- Extend the testing suite to evaluate `nixOnDroidConfigurations`.
- Check for the existence of:
  - `config.build.activationPackage`
  - Specific attributes in `config.environment.variables`.
  - Key packages in `config.environment.systemPackages` (e.g., `git`, `vim`, `openssh`).

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
    - Build all homes (`nix build .#homeConfigurations.USER@HOST.activationPackage`).
    - Cache results to Cachix or generic GitHub Actions cache.

## 4. Non-NixOS System Management via System Manager

**Goal**: Extend uniform configuration management to non-NixOS Linux distributions (e.g., Debian, Ubuntu servers).

**Tool**: [nix-community/system-manager](https://github.com/nix-community/system-manager)

**Plan**:

- Integrate `system-manager` as a flake input.
- Create a new top-level output group (e.g., `systemConfigs` or reuse `nixosConfigurations` with a special builder).
- Define modules that can apply system-level configuration (services, users, etc.) without replacing the host OS kernel/bootloader.
- Allow these systems to coexist with full NixOS systems in the repository.
