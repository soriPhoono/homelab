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
      enable = mkEnableOption "Enable gitops based update cycles on system";
      repo = mkOption {
        type = types.str;
        description = "The url to retrieve the flake configuration from";
        example = "https://github.com/soriphoono/homelab.git";
      };
    };

    config = mkIf cfg.enable (lib.optionalAttrs (options ? services.comin) {
      services.comin = {
        enable = true;
        hostname = config.networking.hostName;
        remotes = [
          {
            name = "origin";
            url = cfg.repo;
            branches.main.name = "main";
          }
        ];
      };
    });
  }
