{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.apps.development.infrastructure.github;
in
  with lib; {
    options.apps.development.infrastructure.github = {
      enable = mkEnableOption ''
        GitHub platform tooling for development workflows (gh CLI + optional GitHub Desktop)
        with token-based gh authentication via sops.
      '';

      enableDesktop = mkOption {
        type = types.bool;
        default = false;
        description = "Install GitHub Desktop GUI.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages = optionals cfg.enableDesktop [pkgs.github-desktop];

        programs.gh.enable = true;
      }
      (mkIf (options ? sops) {
        sops.secrets."api/GITHUB_TOKEN" = {};

        home.activation.ghAuth = hm.dag.entryAfter ["writeBoundary"] ''
          token_path="${config.sops.secrets."api/GITHUB_TOKEN".path}"
          if [ ! -r "$token_path" ]; then
            exit 0
          fi

          if ! ${lib.getExe pkgs.gh} auth status -h github.com >/dev/null 2>&1; then
            ${lib.getExe pkgs.gh} auth login --hostname github.com --git-protocol ssh --with-token < "$token_path" >/dev/null 2>&1 || true
          fi

          ${lib.getExe pkgs.gh} auth setup-git >/dev/null 2>&1 || true
        '';
      })
    ]);
  }
