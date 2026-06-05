# AGENTS.md

## Project Overview

NixOS homelab using flakes with dynamic discovery. Infrastructure-as-code. Host configs in `nix/systems/`, user configs in `nix/homes/`, reusable modules in `nix/modules/`.

## Setup Commands

- Enter dev shell: `direnv allow` or `nix develop`. Evaluates `actions.nix` and regenerates `.github/workflows/`.
- Format: `nix fmt` (treefmt for Nix, YAML, Markdown).
- Validate: `nix flake check` (treefmt + pre-commit hooks).
- Deploy NixOS: `nh os switch .`
- Deploy standalone home: `nh home switch .#<config>`

## Critical Rules

- **Never deploy `nh home switch .#sphoono` on `zephyrus`.** Sphoono is system-integrated via `nix/homes/sphoono@zephyrus`. It deploys as part of `nh os switch .`. Standalone deployment creates conflicting parallel generations.
- **Never edit `.github/workflows/*.yml` by hand.** Edit `actions.nix`, then enter the dev shell to regenerate workflows.

## Architecture

### Dynamic Discovery

`nix/lib/discover` auto-imports modules. You rarely add files to `imports` lists.

- **Modules.** Any `.nix` file or `default.nix` directory under `nix/modules/nixos/` or `nix/modules/home/` is auto-imported.
- **Packages.** Files in `nix/pkgs/` become flake `packages`.
- **NixOS systems.** Directories in `nix/systems/<hostname>/` with `default.nix` become `nixosConfigurations`.
- **Home configs.** Directories in `nix/homes/` are auto-discovered.

### Home Manager

- **Standalone.** `nix/homes/user` or `nix/homes/user@hostname` where `hostname` does not exist in `nix/systems/`. Deploy with `nh home switch .#<name>`.
- **System-integrated.** `nix/homes/user@hostname` where `hostname` exists in `nix/systems/`. Not standalone. Auto-imported via `core.users` module (`nix/modules/nixos/core/users.nix`). Deploys as part of `nh os switch .`.
- **Adding a user.** Add them to `core.users` in the system config. Create `nix/homes/user` and/or `nix/homes/user@hostname` folders. The system auto-imports.

### Directory Layout

```
nix/
  systems/<hostname>/   Host configs (default.nix + disko.nix)
  homes/user@hostname/  Per-host user overrides
  homes/user/           Base user configs
  modules/nixos/        System-level modules
  modules/home/         Home Manager modules
  overlays/             Package overrides
  lib.nix               Custom library (includes discover)
  pkgs/                 Custom packages
.agents/                Agent skills and configuration
docs/                   Project documentation
```

### Context Tiers

Keep guidance in the correct scope.

- **System context.** Host, hardware, OS, platform details. Belongs in NixOS config (`userapps.development.agents.context.system`).
- **User context.** Operator identity, workflow preferences, aliases, personal tooling. Belongs in NixOS config (`userapps.development.agents.context.user`).
- **Project context.** Repository workflows, conventions, agent guidance. Belongs in this file and `.agents/`.

## Hardware & Disk

- Disko manages partitions declaratively in `nix/systems/<hostname>/disko.nix`.
- Hardware facts use `nixos-facter`. To add a system: run `nixos-facter > facter.json`, set `reportPath = ./facter.json;` in its `default.nix`.

## Secrets

- System/user secrets use `sops-nix`. Keys are host SSH keys. Encrypted files must match `.sops.yaml` rules.
- Dev shell secrets use `agenix` + `agenix-shell` (configured in `secrets.nix`). They decrypt automatically in `nix develop` if the identity key is present.
- Never read or print `.yml`/`.yaml` files in `secrets/` or `homes/` without explicit instruction.

## Validation

- Run `nix flake check` before committing.
- Pre-commit hooks run automatically in the dev shell.
- List NixOS hosts: `nix eval .#nixosConfigurations --apply builtins.attrNames`
- List standalone homes: `nix eval .#homeConfigurations --apply builtins.attrNames`
- Dry-run a home build: `nix build .#homeConfigurations.<name>.activationPackage --dry-run`
- Evaluate a host config: `nix eval .#nixosConfigurations.<host>.config.networking.hostName`

## Cloud Environment (Cursor)

### Startup

The update script installs Nix (Determinate installer) and direnv, starts `nix-daemon`, and sources the Nix profile. After that, the dev shell is ready via `nix develop` or `direnv allow`.

### Gotchas

- `nix-daemon` must run for multi-user operations. If builds fail with "cannot connect to socket", run `nix-daemon &>/dev/null &`.
- `[agenix] WARNING: no readable identities found!` is expected in cloud VMs. It does not block evaluation or builds.
- `nix fmt` may reformat YAML in `k3s/`. Revert unrelated changes with `git checkout -- k3s/`.
- Warnings about `eval-cores` and `lazy-trees` are harmless.
- Current NixOS hosts: `zephyrus`, `lg-laptop`. Standalone homes: `sphoono`, `spookyskelly`.

## Agent Skills

Skills live in `.agents/skills/`. Use them for domain-specific guidance.

- `nixos-best-practices` -- mandatory for structural NixOS or Home Manager changes
- `nix-evaluator` -- run as final check after Nix code modifications
- `find-skills` -- discover available skills
- `skill-creator` -- create new skills

## Operational Guidelines

- Prefer surgical edits to existing modules. Create new modules only for new feature sets.
- Commit style: concise, why-focused. Follow the pattern in `git log`.
- Use `nix-evaluator` skill to verify Nix syntax and basic evaluation after changes.
- For system changes, tell the user to run `nh os switch .` or `nh home switch .`.
