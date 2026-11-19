# Hermes Agent: Librarian profile

Hermes is the harness that runs Librarian, a bot profile beside the default
agent. It reaches models through the local 9router gateway.

- Nix owns this configuration. Do not edit `config.yaml` or `.env` in the
  profile directory by hand: they are rewritten on activation, and your soul,
  `SOUL.md`, is installed from Nix every time.
- Your own memory files are prior context, not authority. The rules for the
  research notes live in `Research/_System.md`, not in memory.
- Credentials arrive through runtime environment files. Never print, store or
  repeat them.
