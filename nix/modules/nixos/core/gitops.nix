{
  lib,
  config,
  options,
  ...
}: let
  cfg = config.core.gitops;
in
  with lib; {
    options.core.gitops = {
      enable = mkEnableOption ''
        Enable gitops based update cycles on system
      '';
      automatic = mkEnableOption ''
        Enable automatic updates (for server machines ONLY)
      '';
      repo = mkOption {
        type = types.str;
        description = ''
          The url to retrieve the flake configuration from
        '';
        example = "https://github.com/soriphoono/homelab.git";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      (mkIf (options ? services.comin) {
        services.comin = {
          enable = true;
          remotes = [
            {
              name = "origin";
              url = cfg.repo;
              branches.main.name = "main";
              auth.access_token_path = mkIf (options ? sops) sops.secrets."gitops/auth_key".path;
            }
          ];

          buildConfirmer.mode = mkIf (!cfg.automatic) "manual";
          deployConfirmer.mode = mkIf (!cfg.automatic) "manual";

          desktop = {
            inherit (config.desktop) enable;
            title = "Comin [GitOps Update]:";
          };
        };
      })
      (mkIf (options ? services.comin && options ? sops) {
        sops.secrets."gitops/auth_key" = {};
      })
    ]);
  }
