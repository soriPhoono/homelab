_: {
  projectRootFile = "flake.nix";

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    yamlfmt = {
      enable = true;
      excludes = [
        ".github/workflows/*"
      ];
    };

    mdformat = {
      enable = true;
      excludes = [
        ".agent/workflows/*"
      ];
    };
  };
}
