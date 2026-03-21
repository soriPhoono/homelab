# Contributing to Homelab

## Development Workflow

We follow a **Trunk-Based Development** model with a strict **Issue-First** policy.

### 1. Issue First

Every change must map explicitly to a GitHub Issue. This allows tracking on the project Kanban board.

- **Bug Reports**: Create an issue describing what is broken.
- **Feature Requests**: Create an issue describing the new capability.

### 2. Branching

Create short-lived branches from `main` using the format:

```bash
git checkout -b <type>/<issue-number>-<issue-name>
```

where `<type>` is one of `fix`, `feat`, `chore`, `docs`, `style`, or `refactor`.

*Example*: `fix/123-fix-zsh-typo` or `feat/456-add-k8s-cluster`

### 3. Commit Conventions

We use **Conventional Commits** to keep history clean and automatable.

| Type | Description |
| :--- | :--- |
| `fix:` | A bug fix |
| `feat:` | A new feature |
| `chore:` | Changes to the build process or auxiliary tools and libraries such as documentation generation |
| `docs:` | Documentation only changes |
| `style:` | Changes that do not affect the meaning of the code (white-space, formatting, etc) |
| `refactor:` | A code change that neither fixes a bug nor adds a feature |

*Example*: `feat: add sunshine module for gaming VM`

### 4. Validation

Before pushing, ensure the flake can compile for integration and deployment. The `pre-commit` hooks (managed by `git-hooks` in the flake) should handle this automatically.

To run checks manually:

```bash
nix flake check
```

### 5. Modules and Overlays

Modules in this repository function fundamentally as configuration **overlays**. Instead of acting as independent, isolated scripts, they are designed to be composed together.

- **Configuration Overlays**: When you enable a module (e.g., `services.my-service.enable = true;`), it overlays its specific settings (packages, systemd services, environment variables, etc.) onto the existing system configuration tree.
- **Package Overlays**: Sometimes, modules may also rely on package overlays (`pkgs/` or `overlays/`) to modify or inject custom packages into the global `pkgs` set before the module's configuration is evaluated.

This approach ensures that our infrastructure remains highly modular, reproducible, and easy to extend by stacking these configuration overlays on top of a base system.
