_: {
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    ".agents/skills/*"
    ".gemini/agents/*"
  ];

  programs = {
    alejandra.enable = true;
    deadnix.enable = true;
    statix.enable = true;

    yamlfmt.enable = true;

    mdformat = {
      enable = true;
    };
  };
}
