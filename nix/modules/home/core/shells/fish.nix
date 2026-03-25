{
  lib,
  config,
  ...
}: let
  cfg = config.core.shells.fish;
in
  with lib; {
    options.core.shells.fish = {
      enable = mkEnableOption "Enable the fish shell";

      generateCompletions = mkEnableOption "Generate completions for fish";

      shellInit = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "The extra commands to run on a fish login shell";
        example = "fastfetch";
      };
    };

    config = lib.mkIf cfg.enable {
      programs.fish = {
        inherit (cfg) enable generateCompletions;

        inherit (config.core.shells) shellAliases;

        interactiveShellInit = let
          sessionVariables =
            builtins.concatStringsSep
            "\n"
            (lib.mapAttrsToList
              (name: value: "set ${name} \"${value}\"")
              config.core.shells.sessionVariables);
        in ''
          set fish_greeting

          ${sessionVariables}

          if not set -q SSH_CLIENT
            ${lib.optionalString config.programs.fastfetch.enable "fastfetch"}
          end
        '';
      };
    };
  }
