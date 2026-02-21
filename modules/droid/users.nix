{
  lib,
  config,
  self,
  ...
}: let
  cfg = config.core.user;
in {
  options.core.user = with lib; {
    shell = mkOption {
      type = package;
      default = pkgs.bashInteractive;
      description = "The shell for the user.";
      example = pkgs.zsh;
    };
  };

  config = {
    user.shell = lib.getExe cfg.shell;

    home-manager.config = {
      imports =
        lib.flatten
        (lib.mapAttrsToList (username: _user: let
          base = self + "/homes/${username}";
          droid = self + "/homes/${username}@droid";
        in
          lib.optional (builtins.pathExists base) base
          ++ lib.optional (builtins.pathExists droid) droid)
        cfg.users);
    };
  };
}
