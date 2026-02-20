_: {
  projectRootFile = "flake.nix";
  settings.formatter.yamlfmt.excludes = [".github/workflows/*"];

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    terraform.enable = true;

    yamlfmt.enable = true;

    mdformat.enable = true;
  };
}
