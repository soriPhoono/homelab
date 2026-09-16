_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    actionlint.enable = true;

    yamlfmt = {
      enable = true;
      # github-actions-nix manages formatting for generated workflows.
      excludes = [
        ".github/workflows/ci.yml"
      ];
    };
  };
}
