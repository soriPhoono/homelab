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
        nixd
        alejandra
        vulnix

        age
        agenix
        sops
        ssh-to-age
      ]
      ++ lib.optional stdenv.isLinux [
        disko
        nixos-facter
      ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}

      # Deploy GitHub Actions from actions.nix when that file is modified to create reactive checks in GitHub CI
      mkdir -p .github/workflows
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (
          name: file: let
            safeName = lib.removeSuffix ".yml" name;
          in ''
            cp -f ${file} ./.github/workflows/${safeName}.yml
            chmod +w ./.github/workflows/${safeName}.yml
          ''
        )
        config.githubActions.workflowFiles
      )}
    '';
  }
