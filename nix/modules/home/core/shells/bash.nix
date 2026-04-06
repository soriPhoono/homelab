{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.bash;
in
  with lib; {
    options.core.shells.bash = {
      enable = mkEnableOption "Enable bash shell configuration";
      extraShellInit = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = "Extra shell initialization code";
      };
    };

    config = mkIf cfg.enable (mkMerge [
      {
        programs.bash = {
          enable = true;
          historyControl = ["ignoreboth"];
          initExtra = cfg.extraShellInit;
        };
      }
      (mkIf config.core.secrets.environment.enable {
        programs.bash.initExtra = ''
          source ${config.sops.secrets."environment.env".path}
        '';
      })
    ]);
  }
