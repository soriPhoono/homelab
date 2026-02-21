{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.fish;
in {
  options.core.shells.fish = {
    enable = lib.mkEnableOption "Enable the fish shell";

    shellInit = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "The extra commands to run on a fish login shell";
      example = "fastfetch";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.fish = {
      enable = true;

      shellInitLast = let
        sessionVariables =
          builtins.concatStringsSep
          "\n"
          (lib.mapAttrsToList
            (name: value: "set ${name} \"${value}\"")
            config.core.shells.sessionVariables);

        shellAliases =
          builtins.concatStringsSep
          "\n"
          (lib.mapAttrsToList
            (name: command: "alias ${name}=\"${command}\"")
            config.core.shells.shellAliases);
      in ''
        set fish_greeting

        ${sessionVariables}

        ${shellAliases}

        if not set -q SSH_CLIENT
          ${lib.optionalString config.programs.fastfetch.enable "fastfetch"}
        end
      '';
    };
  };
}
