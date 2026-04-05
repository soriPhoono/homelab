{
  lib,
  config,
  self,
  ...
}: let
  cfg = config.core;
in
  with lib; {
    options.core.user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The username whose home configuration should be imported into this nix-on-droid system.";
      example = "john";
    };

    config = mkIf (cfg.user != null) {
      home-manager.config = {
        imports = let
          userHome = self + "/nix/homes/${cfg.user}";
          # hostName is usually not set in nix-on-droid like it is in nixos,
          # but we could use the droid configuration name if we pass it, or just use the base user.
          # For now, let's just import the base user home.
        in
          optional (pathExists userHome) userHome;

        home = {
          username = "nix-on-droid"; # The actual user in termux/nix-on-droid is always nix-on-droid
          homeDirectory = "/data/data/com.termux.nix/files/home";
        };
      };
    };
  }
