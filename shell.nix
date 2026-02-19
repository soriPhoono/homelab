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
      vulnix

      nodejs

      age
      sops
      ssh-to-age

      disko
      nixos-facter
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}

      alias s="EDITOR=nvim sops"
    '';
  }
