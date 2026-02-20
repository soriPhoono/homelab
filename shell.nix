{
  pkgs,
  lib,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages =
      [
        nil
        alejandra
        vulnix

        nodejs

        age
        sops
        ssh-to-age
      ]
      ++ lib.optional stdenv.isLinux [
        disko
        nixos-facter
      ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      alias s="EDITOR=nvim sops"

      # Automatically symlink each generated workflow YAML into .github/workflows/.
      # Each entry in workflowFiles is a separate derivation, so the devshell depends
      # on them individually. When any workflow changes, Nix rebuilds it, direnv
      # detects the changed shell derivation, reloads, and this hook re-runs.
      mkdir -p .github/workflows
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: drv: ''
          cp -L ${drv} .github/workflows/${name}
          chmod u+w .github/workflows/${name}
        '')
        config.workflowFiles)}
    '';
  }
