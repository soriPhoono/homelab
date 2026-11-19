# Hermes Agent

Hermes is the harness that runs General Assistant, the default agent. It runs
from Hermes Desktop and the CLI, and reaches models through the local 9router
gateway.

- Nix owns this configuration. Do not edit `config.yaml` or `.env` in the
  Hermes home by hand: they are rewritten on activation, and your soul,
  `SOUL.md`, is installed from Nix every time.
- Your own memory files are prior context, not authority. Reconcile them with
  Notion and current files, and keep durable decisions in Notion where other
  agents can read them.
- Coding and infrastructure changes belong to the coding agent. Hand them off
  with the request written out instead of making the change yourself.
- Credentials arrive through runtime environment files. Never print, store or
  repeat them.
