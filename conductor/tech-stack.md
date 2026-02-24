# Technology Stack

## Core Technologies

- **Nix & NixOS**: The foundational declarative configuration language and operating system.
- **Home Manager**: For managing user-specific environments and dotfiles.
- **Nix-on-Droid**: Extending Nix capabilities to Android devices.

## Project Structure & Management

- **Nix Flakes**: Provides hermetic builds and dependency locking.
- **Flake-parts**: Modularizes the flake configuration for better maintainability.

## Systems & Infrastructure

- **Disko**: Declarative disk partitioning and formatting.
- **Lanzaboote**: Secure Boot support for NixOS.
- **Comin**: Deployment via a GitOps pull-based approach.
- **Nixos-facter-modules**: Hardware detection and reporting.

## Secrets & Security

- **Agenix**: Age-based secret encryption for NixOS.
- **Sops-nix**: Integration for SOPS (Secrets Operation) in Nix.
- **Vulnix**: Vulnerability scanner for the Nix system closures.

## Editor & Applications

- **NVF**: Neovim configuration framework for Nix.
- **NUR (Nix User Repository)**: Access to community-maintained packages.

## Development & Automation

- **Treefmt-nix**: Unified formatting for the entire repository.
- **Git-hooks-nix**: Pre-commit hooks to ensure code quality.
- **Github-actions-nix**: Declarative GitHub Actions workflows.
- **Agenix-shell**: Secrets integration for development shells.
