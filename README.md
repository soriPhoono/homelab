# Homelab: The Data Fortress

## Project Overview
This repository serves as an all-in-one "Data Fortress," a comprehensive declarative configuration for my personal infrastructure. It is built to evolve into a self-hosted GitOps-powered Kubernetes cluster along with other devices designed to integrate with it, managing everything from single-board computers (Raspberry Pis) to primary edge devices and virtualized gaming systems (like "Gaming on Whales" via Sunshine/Moonlight).

## Philosophy: Single Command Invocation
The core philosophy of this project is **"Single Command Invocation"**.
-   **No manual scripts**: If a task requires more than a standard Nix command, the flake needs to be fixed.
-   **Stability**: `nix flake check` serves as the gold standard for repository health. If the check passes, the system is considered stable for iteration.
-   **Declarative**: Every aspect of the infrastructure is defined in code.

## Directory Structure

| Directory     | Description |
| :---          | :--- |
| **`systems/`**   | Top-level NixOS configurations for physical and virtual machines. |
| **`homes/`**     | Home Manager configurations for user environments (desktop, terminal, apps). |
| **`modules/`**   | Reusable NixOS and Home Manager modules. |
| **`pkgs/`**      | Custom packages not found in upstream Nixpkgs. |
| **`overlays/`**  | Modifications to upstream packages to alter their behavior or versions. |
| **`templates/`** | Scaffolding for creating new systems, modules, or packages. |

## Quick Start

The development environment is automatically managed via `direnv`.

1.  **Enter the Shell**:
    Simply `cd` into the directory. If you have `direnv` and `nix` installed, the environment will load automatically:
    ```bash
    direnv allow
    ```
    Alternatively, use:
    ```bash
    nix develop
    ```

2.  **Validate the Codebase**:
    Run the standard check to ensure everything is correct:
    ```bash
    nix flake check
    ```

## Dependencies
-   **Nix**: The package manager and build tool.
-   **Direnv**: For automatic environment loading.

Everything else is provided by the flake devShell.
