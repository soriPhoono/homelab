# Development Experience

This project is designed with a "developer-first" workflow, focusing on modularity, fast iteration, and secure secrets handling.

## 🧩 Modularity with `flake-parts`

We utilize [flake-parts](https://github.com/hercules-ci/flake-parts) to break down a monolithic `flake.nix` into granular, manageable segments. This allows us to define:

- `devShells` for project-specific environments.
- `apps` for custom maintenance tasks (e.g., security audits).
- `checks` for automated validation and unit testing.

## 🔐 Secrets Handling

### agenix-shell

For developer-level secrets (API keys, tokens used during development), we use `agenix-shell`.

- Secrets are encrypted via SSH keys.
- When you enter the `nix develop` environment, `agenix-shell` automatically decrypts and exports the necessary environment variables.
- This ensures that sensitive credentials never hit the git history but are seamlessly available to your tools.

### sops-nix

For system-level and user-level persistent secrets (passwords, private keys), we use `sops-nix`. This integrates directly into the NixOS and Home Manager activation cycles.

## 🛠️ Unified Workflow

- **Check**: `nix flake check` runs broad validation.
- **Format**: `treefmt` ensures consistent code style across the repo.
- **Switch**: We use `nh os switch .` (Nix Helper) for faster, simplified system updates.
