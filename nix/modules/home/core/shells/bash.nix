{
  lib,
  config,
  options,
  ...
}:
with lib; {
  programs.bash = mkMerge [
    {
      enable = true;
      historyControl = ["ignoreboth"];
    }
    (optionalAttrs (options ? sops && config.core.secrets.environment.enable) {
      initExtra = ''
        source ${config.sops.secrets."environment.env".path}
      '';
    })
  ];
}
