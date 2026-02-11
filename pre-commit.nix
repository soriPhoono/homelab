{pkgs, ...}: {
  settings.hooks = {
    nil.enable = true;
    statix.enable = true;
    deadnix.enable = true;

    treefmt.enable = true;

    gitleaks = {
      enable = true;
      name = "gitleaks";
      entry = "${pkgs.gitleaks}/bin/gitleaks protect --verbose --redact --staged";
    };

    actionlint.enable = true;
  };
}
