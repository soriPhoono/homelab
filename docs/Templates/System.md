______________________________________________________________________

## type: system model: \<% tp.file.cursor(1) %> os: nixos tags: [system]

# \<% tp.file.title %>

## Hardware Specs

- **CPU**:
- **RAM**:
- **Storage**:

## Role

<!-- Primary function of this machine (e.g., K8s Master, Desktop, Router) -->

## Unique Configurations

<!-- Specific overrides or hardware quirks handled here -->

## Deployment

```bash
nixos-rebuild switch --flake .#<% tp.file.title %>
```
