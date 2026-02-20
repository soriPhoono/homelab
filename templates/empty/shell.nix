{
  pkgs,
  config,
  ...
}:
with pkgs;
  mkShell {
    packages = [
      nil
      alejandra
      agenix
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      alias s="EDITOR=nvim sops"
    '';
  }
