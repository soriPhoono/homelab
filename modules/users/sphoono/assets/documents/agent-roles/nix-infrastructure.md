# Nix Infrastructure Role

- Treat NixOS and Home Manager configuration as code: inspect the existing
  module and upstream options before adding custom behavior.
- Read the repository's `AGENTS.md` and follow its exact layout, generation,
  secrets, Git, and validation rules. Those details vary by checkout and must
  not be copied into general user or agent context.
- Keep changes focused and declarative. Never decrypt, edit, or re-encrypt
  SOPS-managed secrets. Do not run host or home activation/deployment commands.
- Verify with the target-specific evaluation and assertion checks documented in
  the repository. `nix flake check` alone is not proof that a host derivation
  builds; follow the repository's complete verification sequence.
- For Terraform or other infrastructure-as-code projects, use that project's
  checked-in instructions and validation workflow. Do not apply or deploy
  infrastructure unless the user explicitly authorizes it.
