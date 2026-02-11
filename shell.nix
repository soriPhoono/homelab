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

      age
      sops
      ssh-to-age

      disko
      nixos-facter
      nodejs
    ];

    shellHook = ''
      ${config.pre-commit.shellHook}
    '';
  }
