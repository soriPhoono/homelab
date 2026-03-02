{
  self,
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core.user;
in {
  options.core.user = with lib; {
    userName = mkOption {
      type = with types; nullOr str;
      default = null;
      description = "The username for the user.";
    };

    shell = mkOption {
      type = types.package;
      default = pkgs.bashInteractive;
      description = "The shell for the user.";
      example = pkgs.zsh;
    };
  };

  config = {
    user.shell = lib.getExe cfg.shell;

    home-manager.config = {
      imports =
        if cfg.userName == null
        then []
        else let
          userHome = self + "/homes/${cfg.userName}";
          globalHome = self + "/homes/${cfg.userName}@global";
          droidHome = self + "/homes/${cfg.userName}@droid";
        in
          lib.filter builtins.pathExists [
            userHome
            globalHome
            droidHome
          ];

      # home = {
      #   username = config.user.userName;
      # };

      core = {
        shells.fish.enable = (lib.getName cfg.shell) == "fish";
      };
    };
  };
}
