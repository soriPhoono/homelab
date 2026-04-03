# Work on complete rewrite or migrate to helix
{pkgs, ...}: {
  config.vim = import ./settings.nix {inherit pkgs;};
}
