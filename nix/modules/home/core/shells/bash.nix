{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.bash;
in
  with lib; {
    options.core.shells.bash.enable = mkEnableOption "Enable bash shell configuration";

    config = mkIf cfg.enable (mkMerge [
      {
        programs.bash.enable = true;
      }
      (mkIf config.core.secrets.environment.enable {
        programs.bash.initExtra = ''
          source ${config.sops.secrets."environment.env".path}
        '';
      })
    ]);
  }
