# Security & Auditing

Security is a core pillar of the homelab, focusing on malware protection, auditing, and secure network isolation.

## 🛡️ Malware Protection (ClamAV)

ClamAV is enabled as a core service on all systems. It provides:

- **Periodic Scanning**: Scheduled scans for known threats.
- **On-Access Scanning**: Real-time protection for key user directories.
- **Freshclam**: Automatic signature updates.

## 🔍 System Auditing

We use a custom `audit` app (integrated into the flake) to check for vulnerable packages.

- **Vulnix**: Scans the system against the NixOS vulnerability database.
- **Whitelist**: A local `vulnix-whitelist.toml` tracks and excludes known-safe exceptions.

Run the audit with:

```bash
nix run .#audit
```

## 🌐 Network Isolation & Privacy

- **Tailscale**: Secure mesh networking for encrypted host-to-host communication.
- **Gluetun**: VPN integration for specific services, ensuring traffic is routed through secure tunnels.
- **Pi-hole**: DNS-level ad and tracker blocking (hosted in the Talos cluster).

## 🔑 Secrets Management

- **sops-nix**: PGP/Age encrypted secrets for system configurations.
- **agenix-shell**: Secure delivery of developer environment variables.
