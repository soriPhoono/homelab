{
  lib,
  pkgs,
  config,
  options,
  ...
}: let
  cfg = config.userapps.development.infrastructure.github;
in
  with lib; {
    options.userapps.development.infrastructure.github = {
      enable = mkEnableOption ''
        GitHub platform tooling for development workflows (gh CLI + optional GitHub Desktop)
        with token-based gh authentication via sops.
      '';

      enableCli = mkOption {
        type = types.bool;
        default = true;
        description = "Install and configure GitHub CLI (`gh`).";
      };

      enableDesktop = mkOption {
        type = types.bool;
        default = false;
        description = "Install GitHub Desktop GUI.";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        home.packages =
          (optionals cfg.enableCli [pkgs.gh])
          ++ (optionals cfg.enableDesktop [pkgs.github-desktop]);

        programs.gh.enable = mkDefault cfg.enableCli;
      }
      (mkIf (options ? sops && cfg.enableCli) {
        sops.secrets."api/GITHUB_API_KEY" = {};

        home.activation.ghAuth = hm.dag.entryAfter ["writeBoundary"] ''
          token_path="${config.sops.secrets."api/GITHUB_API_KEY".path}"
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
