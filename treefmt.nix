_: {
  projectRootFile = "flake.nix";

  settings.global.excludes = [
    ".agents/skills/*"
    ".gemini/agents/*"
    # Flux bootstrap manifests; yamlfmt output diverges from `flux install --export`.
    "k3s/clusters/**/flux-system/**"
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
