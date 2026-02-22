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
      enable = true;
      name = "action-validator";
      description = "Validate GitHub Action workflows";
      files = "^.github/workflows/";
      entry = let
        script = pkgs.writeShellScript "action-validator-wrapper" ''
          set -e
          for file in "$@"; do
            ${pkgs.action-validator}/bin/action-validator "$file"
          done
        '';
      in "${script}";
    };
  };
}
