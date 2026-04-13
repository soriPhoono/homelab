{
  lib,
  config,
  ...
}:
with lib; {
  config = mkIf config.core.secrets.environment.enable {
    programs.bash.initExtra = ''
      source ${config.sops.secrets."environment.env".path}
    '';
  };
}
