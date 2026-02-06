# Contributing to Homelab

## Development Workflow

We follow a **Trunk-Based Development** model with a strict **Issue-First** policy.

### 1. Issue First
Every change must map explicitly to a GitHub Issue. This allows tracking on the project Kanban board.
-   **Bug Reports**: Create an issue describing what is broken.
-   **Feature Requests**: Create an issue describing the new capability.

### 2. Branching
Create short-lived branches from `main` using the format:
```bash
git checkout -b dev-<issue-name>
```
*Example*: `dev-fix-zsh-typo` or `dev-add-k8s-cluster`

### 3. Commit Conventions
We use **Conventional Commits** to keep history clean and automatable.

| Type | Description |
| :--- | :--- |
| `feat:` | A new feature |
| `fix:` | A bug fix |
| `docs:` | Documentation only changes |
| `style:` | Changes that do not affect the meaning of the code (white-space, formatting, etc) |
| `refactor:` | A code change that neither fixes a bug nor adds a feature |
| `perf:` | A code change that improves performance |
| `test:` | Adding missing tests or correcting existing tests |
| `chore:` | Changes to the build process or auxiliary tools and libraries such as documentation generation |

*Example*: `feat: add sunshine module for gaming VM`

### 4. Validation
Before pushing, ensure the fortress can compile for integration and deployment. The `pre-commit` hooks (managed by `git-hooks` in the flake) should handle this automatically.
To run checks manually:
```bash
nix flake check
```
