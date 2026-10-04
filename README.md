# homelab

> Declarative NixOS and home-manager configuration, composed from
> aspects.

Personal infrastructure as a single Nix flake. Hosts, users and home
environments are assembled from small reusable units rather than
per-machine configuration files.

## Highlights

- **Dendritic module tree.** Every `.nix` file under `modules/` is a
  flake-parts module, auto-imported by [import-tree]. There is no
  central import list to maintain: adding a file adds it to the flake.
- **Aspect composition.** Configuration lives in [den] _aspects_ —
  named units that hosts, users and homes pull in through `includes`.
  Optional layers hang off a base aspect as sub-aspects, so a machine
  opts into exactly what it needs and nothing more.
- **Hardware detection over hardcoding.** Each host carries a
  [nixos-facter] report that drives kernel modules, initrd contents and
  firmware. Aspects describe intent; facter supplies the per-machine
  specifics.
- **Secrets at rest.** [sops-nix] with per-host age recipients. Only
  encrypted material and public keys are committed.
- **Generated flake boilerplate.** `flake.nix` is produced by
  [flake-file] from `modules/inputs.nix`, so inputs are declared once
  in a module like everything else.
- **Checked on every change.** A dev shell entered automatically by
  direnv, twelve pre-commit hooks, and a CI workflow building the
  flake's checks, packages and dev shells.

## Composition

A host is a list of aspects. Optional capability comes from opting into
a sub-aspect rather than from toggling options:

```nix
den.aspects.laptop-ares.includes = [
  den.aspects.core.hardware.cpu.amd
  den.aspects.core.hardware.gpu.amd # driver, firmware, monitoring
  den.aspects.core.hardware.gpu.nvidia.laptop # PRIME offload
  den.aspects.core.bootloaders.systemd-boot
  den.aspects.core.swap.zram-swap
];
```

Adding GPU compute to that machine means including
`den.aspects.core.hardware.gpu.amd.gpgpu`, which layers ROCm and OpenCL
onto the same base aspect. Nothing else changes.

## Structure

- `modules/aspects/` — the reusable aspects, and the bulk of the repo.
- `modules/systems/nixos/<host>/` — per-host configuration, disk layout
  and hardware report.
- `modules/users/`, `modules/homes/` — user aspects and home-manager
  homes.
- `modules/inputs.nix` — flake inputs.
- `flake-system/` — flake-parts plumbing: dev shell, formatter,
  pre-commit hooks, CI workflow generators.
- `secrets/` — sops-encrypted secrets.
- `.agents/` — research wikis for agent-assisted work.

## Getting started

```sh
nix develop          # or let direnv do it on cd
```

The shell carries the Nix toolchain (`nil`, `statix`, `deadnix`,
`nixfmt`), secrets tooling (`sops`, `age`, `ssh-to-age`) and the
formatter and hooks used by CI.

## Outputs

Host and home packages are [nh] wrappers; they take an action argument
and default to `build`.

```sh
nix run .#laptop-ares            # build the host closure
nix run .#laptop-ares switch     # build and activate it
nix run .#sphoono                # build the home-manager generation

nix run .#vm-laptop-ares         # boot the host in a QEMU VM

nix run .#write-flake            # regenerate flake.nix from inputs.nix
nix fmt                          # treefmt across the tree
nix flake check                  # flake-file, pre-commit and treefmt
```

Note that `nix flake check` covers only those three checks. Host
breakage surfaces when the packages are built, which is what CI does.

## Secrets

`secrets/` holds sops-encrypted files; `.sops.yaml` lists the public age
recipients and documents how to enrol a new host key. Nothing decrypted
is ever committed.

## Working with agents

[AGENTS.md](AGENTS.md) is the operational manual for AI agents working
in this repository: layout, conventions, verification gates and the
research-wiki protocol. `CLAUDE.md` symlinks to it.

## Installing a new host

Not yet documented. The provisioning flow is being reworked and the
steps will be written down once they are verified end to end.

## License

GPL-3.0-or-later. See [LICENSE.md](LICENSE.md).

[den]: https://den.denful.dev/
[flake-file]: https://github.com/denful/flake-file
[import-tree]: https://github.com/denful/import-tree
[nh]: https://github.com/nix-community/nh
[nixos-facter]: https://github.com/nix-community/nixos-facter
[sops-nix]: https://github.com/Mic92/sops-nix
