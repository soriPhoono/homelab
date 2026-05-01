{
  lib,
  pkgs,
  config,
  ...
}: let
  longhornctl = pkgs.callPackage ./nix/pkgs/longhornctl {};
in
  with pkgs;
    mkShell {
      packages =
        [
          # Nix
          nixd
          alejandra
          vulnix

          # Secrets
          age
          agenix-cli
          sops
          ssh-to-age

          # K3s
          k3d

          # Kubernetes
          kubectl
          kubernetes-helm
          fluxcd
          kubeseal
          k9s
          longhornctl
        ]
        ++ lib.optional stdenv.isLinux [
          disko
          nixos-facter
          openiscsi
        ];

      shellHook = ''
        ${config.pre-commit.shellHook}
        source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

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
