{
  lib,
  config,
  options,
  ...
}:
with lib; {
  config = mkIf config.core.secrets.environment.enable {
    programs.bash.initExtra = mkIf (options ? sops) ''
      source ${config.sops.secrets."shell/environment.env".path}
    '';
  };
}
