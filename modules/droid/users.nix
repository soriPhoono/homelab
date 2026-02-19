{
  lib,
  config,
  self,
  ...
}: let
  cfg = config.core;
in {
  options.core.users = with lib;
    mkOption {
      type = with types;
        attrsOf (submodule {
          options = {
            # We can add more options here if needed, matching NixOS module
            # For now, just existence is enough trigger imports
          };
        });
      default = {};
      description = "List of users to configure for Nix-on-Droid.";
    };

  config = lib.mkIf (cfg.users != {}) {
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
