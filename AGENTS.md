# Homelab agent instructions

Nix flake for sphoono's NixOS homelab and personal devices. It builds NixOS systems, standalone Home Manager profiles, shared modules, overlays, generated GitHub Actions, treefmt formatting, and sops-nix/agenix-shell secret workflows.

## Scope and guardrails

- **Do not deploy.** Write config and verify evaluation/builds; hand off `nh os switch`, `nh home switch`, `nixos-rebuild`, and `home-manager switch` to the user.
- Keep changes focused to the smallest file or module that owns the option/config; no drive-by refactors or mass formatting.
- Prefer nixpkgs, Home Manager, NixOS modules, and existing repo helpers before adding custom code.
- Use one logical commit per change with Conventional Commit prefixes (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`) if committing.

## Layout

- `flake.nix` uses `flake-parts`; `mkSystem` builds `nix/systems/<hostname>` and `mkHome` builds standalone homes from `nix/homes/<user>` / `nix/homes/<user>@<name>`.
- `nix/lib.nix` extends nixpkgs lib with `homelab.helpers.core.discover`, `homelab.development.*`, and `homelab.containers.*` helpers.
- `nix/modules/nixos/` is system-level modules: `core`, `desktop`, `hosting`, `themes`.
- `nix/modules/home/` is Home Manager modules: `core`, `desktop`, `apps`, `programs`.
- `nix/homes/AGENTS.md` and user-local AGENTS files contain extra rules for Home Manager layering.
- `nix/overlays/default.nix` auto-loads every sibling `.nix` overlay except `default.nix`.

## Current targets

- NixOS systems exported by `self.nixosConfigurations`: `desktop-ares`, `laptop-ares`, `laptop-vesper`.
- Standalone homes exported by `self.homeConfigurations`: `sphoono`, `spookyskelly`.
- Host-specific homes whose host exists under `nix/systems/` are consumed by the NixOS system build, not exported standalone.
- Systems declare architecture in `nix/systems/<hostname>/meta.json`; current hosts are `x86_64-linux`.

## Dev environment

- Enter the dev shell with `nix develop`.
- Dev shell packages include `gh`, `nixd`, `nil`, `alejandra`, `vulnix`, `age`, `agenix-cli`, `sops`, `ssh-to-age`, `secretspec`; Linux also gets `disko` and `nixos-facter`.
- `shell.nix` runs the pre-commit hook setup and regenerates `.github/workflows/*.yml` from `actions.nix`.

## Build, check, format

- Full evaluation gate: `nix flake check --all-systems`.
- Default-system evaluation: `nix flake check`.
- Format/lint through treefmt: `nix fmt`.
- Build a NixOS system: `nix build .#nixosConfigurations.desktop-ares.config.system.build.toplevel`.
- Build another system by replacing the hostname with `laptop-ares` or `laptop-vesper`.
- Build standalone homes:
  - `nix build .#homeConfigurations.sphoono.activationPackage`
  - `nix build .#homeConfigurations.spookyskelly.activationPackage`

## CI and generated files

- `actions.nix` is the source for `.github/workflows/ci.yml`; do not hand-edit `ci.yml` except to inspect generated output.
- CI runs on pull requests and gates on `nix flake check --all-systems`, then builds each exported NixOS system and standalone home activation package.
- `.github/workflows/update-flake-lock.yml` is hand-written and opens weekly `chore(deps): update flake.lock` PRs.

## Formatting and hooks

- `treefmt.nix` enables `alejandra`, `deadnix`, `statix`, `actionlint`, `yamlfmt`, and `mdformat`.
- `pre-commit.nix` enables `nil`, `treefmt`, and `gitleaks protect --verbose --redact --staged`.
- Treefmt excludes `.agents/skills/*`, `.cursor/rules/*`, `.gemini/agents/*`; `yamlfmt` excludes generated `.github/workflows/ci.yml`.

## Nix conventions observed here

- Modules commonly use `{ lib, config, pkgs, ... }: with lib; { ... }` or a `let cfg = ...; in with lib; { ... }` shape.
- Define options with `mkEnableOption` / `mkOption`, explicit `type`, `default`, `description`, and `example` where helpful.
- Compose conditionally with `mkIf`, `mkMerge`, `mkDefault`, `mkForce`, `optional`, `optionalAttrs`, and `mkBefore`.
- Add NixOS modules by creating `nix/modules/nixos/<area>/<name>.nix` or `<name>/default.nix`; auto-discovery imports it through the nearest `default.nix`.
- Add Home Manager modules the same way under `nix/modules/home/`.
- Add overlays as `nix/overlays/<name>.nix`; `nix/overlays/default.nix` imports them automatically.

## Secrets

- Secret rules live in `.sops.yaml`; user secrets live under `nix/homes/<user>/secrets.yml`; system secrets live under `nix/systems/<hostname>/secrets.yml`.
- Edit secrets with exact paths, e.g. `sops nix/systems/desktop-ares/secrets.yml` or `sops nix/homes/sphoono/secrets.yml`.
- Do not put secrets in module `environment` attrs; `lib.homelab.development.mkAgent` explicitly treats environment variables as non-secret.

## Pitfalls

- Existing older host names like `zephyrus`, `ares`, `lg-laptop`, and `testbench` are stale for current flake outputs; use `desktop-ares`, `laptop-ares`, and `laptop-vesper`.
- `nix build .#homeConfigurations.sphoono@desktop-ares.activationPackage` is not a valid exported target for NixOS-managed hosts.
- Editing `actions.nix` requires entering `nix develop` or otherwise regenerating/validating the generated workflow before committing.
- `nix flake check --all-systems` evaluates all checks and can be slower than a targeted `nix build` during iteration.
