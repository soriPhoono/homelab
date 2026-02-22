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
      pass_filenames = false;
    };

    actionlint.enable = true;

    action-validator = {
    action-validator = {
      enable = true;
      name = "action-validator";
      description = "Validate GitHub Action workflows";
      files = "^.github/workflows/.*\\.ya?ml$";
      entry = "${pkgs.action-validator}/bin/action-validator";
      require_serial = true;
    };
}
