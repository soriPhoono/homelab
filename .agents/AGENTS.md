# Agent Infrastructure & Repository Guide

This directory (`.agents/`) is the central hub for agent-specific intelligence, skills, and operational guidelines. Use this guide to navigate the repository and utilize the available agent tooling effectively.

## Repository Overview

This is a **NixOS Homelab ("The Data Fortress")** repository. It is highly modular and utilizes dynamic discovery for configurations.

### Directory Structure Map

- **`/nix/`**: Core Nix logic.
  - **`systems/`**: Host configurations (e.g., `zephyrus`, `lg-laptop`). Each folder contains a `default.nix` and `disko.nix`.
  - **`homes/`**: User configurations.
    - `user/`: Base user config.
    - `user@host/`: Host-specific user overrides.
  - **`modules/`**: Reusable modules.
    - `nixos/`: System-level modules.
    - `home/`: Home Manager-level modules.
  - **`overlays/`**: Package overrides for inside NixOS and Home Manager configurations.
  - **`lib.nix`**: Custom library functions that are used across the repository (includes the `discover` logic).
- **`/.agents/`**: Agent-specific configuration and documentation.
  - **`skills/`**: Specialized agent skills.
- **`/docs/`**: General system and project documentation.

## Agent Skills System

Skills are specialized instruction sets that provide expert guidance for specific domains.

### How to Use Skills

1. **Discover**: If you are unsure how to perform a task, use the `find-skills` skill or search `.agents/skills/`.
1. **Activate**: Use the `activate_skill` tool with the skill's name (e.g., `nixos-best-practices`).
1. **Follow**: Once activated, prioritize the instructions in the `<activated_skill>` tags over general defaults.

### Available Skills

- **`nixos-best-practices`**: Mandatory for structural changes to NixOS/Home Manager configs.
- **`nix-evaluator`**: Use this as a final check for any Nix code modifications.
- **`find-skills`**: Helps you discover other skills.
- **`skill-creator`**: Use this if you need to create a new skill for the project.

## Operational Mandates for Agents

### 1. Research & Discovery

- **Root `AGENTS.md`**: Always refer to the root `AGENTS.md` for the most critical system-wide technical rules (Secrets, Hardware, Workflow).
- **Dynamic Discovery**: Be aware that many modules are imported automatically via `lib.homelab.discover`. You rarely need to add files to `imports` lists manually.

### 2. Implementation Workflow

- **Surgical Edits**: Prefer precise edits to existing modules over creating new ones unless a new feature set is required.
- **Validation**:
  - Use `nix-evaluator` skill to verify Nix syntax and basic evaluation.
  - For system changes, advise the user to run `nh os switch .` or `nh home switch .`.
- **Commit Style**: Follow the style established in `git log`. Usually concise and "why" focused.

### 3. Safety & Integrity

- **Secrets**: NEVER touch or print `.yml` or `.yaml` files in `secrets/` or `homes/` without explicit instruction. These are managed via `sops-nix`.
- **Workflows**: Do NOT edit `.github/workflows/` directly. Edit `actions.nix` in the root and allow the dev shell to regenerate them.

## Key Technical Facts

- **Host Discovery**: If a host exists in `nix/systems/`, its corresponding `nix/homes/user@host` is **NOT** a standalone configuration; it's integrated into the system config.
- **Standalone Homes**: Homes for hosts that do **not** exist in `nix/systems/` (or `user@droid`) are exported as standalone Home Manager configurations.
- **Hardware**: Hardware facts are stored in `facter.json` within host directories.
