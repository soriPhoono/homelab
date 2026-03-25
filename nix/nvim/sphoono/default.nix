{pkgs, ...}: {
  config.vim = import ./settings.nix {inherit pkgs;};
}
