{
  lib,
  pkgs,
  config,
  options,
  ...
}:
with lib; {
  options.core.shells.bash = {
    enable = mkEnableOption "Enable the bash shell";

    interactiveShell = mkOption {
      type = with types; nullOr package;
      default = null;
      description = ''
        Interactive shell to auto-execute from bash for interactive sessions.
        When set, bash handles non-interactive commands (e.g. SSH remote
        commands) while this shell is launched for interactive terminals.
        Set to null to always use bash.
      '';
      example = pkgs.fish;
    };
  };

  config = mkIf config.core.shells.bash.enable {
    programs.bash = {
      enable = true;

      initExtra = mkMerge [
        (mkIf (config.core.shells.bash.interactiveShell != null) ''
          # Auto-launch the configured interactive shell for interactive sessions.
          # Non-interactive sessions (e.g. SSH remote commands) stay in bash so
          # POSIX shell syntax from tools like Hermes desktop works.
          if [ -n "$PS1" ] && [ -t 1 ]; then
            exec ${config.core.shells.bash.interactiveShell}/bin/${config.core.shells.bash.interactiveShell.meta.mainProgram or config.core.shells.bash.interactiveShell.pname or "fish"} "$@"
          fi
        '')
        (mkIf config.core.secrets.environment.enable (mkIf (options ? sops) ''
          source ${config.sops.secrets."shell/environment.env".path}
        ''))
      ];
    };
  };
}
