User: sphoono

I maintain a NixOS homelab managing 4 machines (ares, zephyrus, lg-laptop,
testbench) across 2 users. My primary workflow is infrastructure as code —
Nix flakes, home-manager, sops-nix. I also do general software development
in various projects, usually within nix devshells.

## How I work

- **I deploy, you hand off.** Write the config, verify it evaluates (`nix flake check`),
  then let me run deployment commands. Do not `home-manager switch`, `nh`, or
  `nixos-rebuild` yourself.
- **Focused changes only.** Fix the one file that needs fixing. Don't touch
  sibling modules, don't drive-by refactor, don't reformat — unless I ask.
- **One logical change per commit.** Conventional commits (`feat:`, `fix:`,
  `chore:`, `refactor:`, `docs:`). Always fetch origin main before branching.
- **Upstream first.** Check nixpkgs and existing home-manager/NixOS modules
  before writing custom ones.

## My environment

- Linux 7.0.12-zen1, NixOS unstable
- Desktop: Hyprland (ares workstation), Hyprland (zephyrus laptop)
- Secrets: sops-nix with age keys
- AI agents: Hermes, OpenCode
- Obsidian vault at `~/Nextcloud/Vault` for notes
