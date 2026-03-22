# Agent Instructions for Homelab

This file provides context and rules for AI agents working in this repository.

## Project Structure

- **Core Config Location**: All actual Nix configuration code (systems, homes, templates, modules, overlays, pkgs, etc.) is centralized in the `nix/` subfolder.
- The root `flake.nix` imports from those subpaths.

## Development Workflow

- The project follows a **Trunk-Based Development** model with a strict **Issue-First** policy.
- **Branch Naming**: Branches must be created from `main` in the format:
  ```bash
  <type>/<identifier>-<description>
  ```bash
  <type>/<issue-number>-<issue-name>
  ```
  Where `<type>` is one of `fix`, `feat`, `chore`, `docs`, `style`, or `refactor`. (e.g., `feat/456-add-k8s-cluster`).

## Commit Conventions

- The project strictly uses **Conventional Commits** for all commit messages.

## Nix Guidelines

- **Module Architecture**: Nix modules in this repository function fundamentally as **configuration overlays** designed to be composed together (e.g., via `enable = true;`) rather than acting as independent, isolated scripts.
- **Module Imports**: When importing Nix modules, prefer importing a directory (which implicitly loads `default.nix`) over explicitly listing individual `.nix` files.

## Testing & Validation

- Use `nix flake check` as the standard execution command to test and validate Nix flake configurations for errors. If it fails, fix the code before pushing.

## Testing & Validation

- Use `nix flake check` as the standard execution command to test and validate Nix flake configurations for errors. If it fails, fix the code before pushing.
- **Linting**: The repository uses `nil`, `statix`, and `deadnix` for linting. Ensure your changes pass these checks.
- **Security**: `gitleaks` is active in pre-commit hooks to prevent secret exposure. Never commit sensitive information.

- Use `nix fmt` as the standard command to auto-format the repository and resolve treefmt errors.

## Special Environment Instructions

- To install Nix in restricted environments (e.g., if encountering seccomp BPF errors), use the Determinate Systems installer with syscall filtering disabled:
  ```bash
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install linux --no-confirm --extra-conf "filter-syscalls = false"
  ```
- Always source the environment before running Nix commands and be sure to allow the devshell:
  ```bash
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  direnv allow
  ```
