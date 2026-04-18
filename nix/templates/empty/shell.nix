{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nixd
      alejandra

      # age
      # agenix-cli
    ];

    shellHook = ''
      source ${config.agenix-shell.installationScript}/bin/install-agenix-shell

      ${config.pre-commit.shellHook}
    '';
  }
