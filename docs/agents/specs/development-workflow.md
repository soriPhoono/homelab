# Development Workflow Spec

This spec outlines the mandatory procedures for making changes to this repository, ensuring consistency, safety, and security.

## Core Rules

1. **Issue-First Policy**: All changes must be linked to a GitHub issue.
1. **Trunk-Based Development**: All changes must be made via pull requests to the `main` branch.
1. **Conventional Commits**: Commit messages must follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard.

## Branch Naming Convention

Branches must follow the format `<type>/<identifier>-<description>`:

- `fix/`: Bug fixes.
- `feat/`: New features.
- `chore/`: Maintenance tasks.
- `docs/`: Documentation updates.
- `style/`: Code style changes.
- `refactor/`: Code refactoring.

Example: `feat/456-add-k8s-cluster`

## Making Changes

1. **Create a Branch**: From `main`, create a branch following the naming convention.
1. **Research & Strategy**: Understand the existing modules and how your change fits into the architecture.
1. **Implementation**: Make focused, surgical changes.
1. **Local Validation**:
   - `nix flake check`: Validate flake configurations for errors.
   - `nix fmt`: Auto-format all files.
   - `direnv allow`: Ensure development shell is active and secure.
1. **Commit**: Use Conventional Commits.
1. **Pull Request**: Create a PR and ensure all CI/CD checks (GitHub Actions) pass.

## Security & Linting

- **Gitleaks**: Active in pre-commit hooks to prevent secret exposure.
- **Linters**: `nil`, `statix`, and `deadnix` are used for Nix files.
- **Pre-commit Hooks**: Managed by `git-hooks-nix` and defined in `pre-commit.nix`.
