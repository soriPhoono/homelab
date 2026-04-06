{
  lib,
  config,
  self,
  pkgs,
  ...
}: let
  cfg = config.core.user;
in
  with lib; {
    options.core.user = {
      name = mkOption {
        type = types.str;
        default = "nix-on-droid";
        description = ''
          The name of the user whose home configuration should be imported into this nix-on-droid system.
          This is usually the same as the username, but can be different if you want to use a different
          home configuration for the same user (multi user repositories).
        '';
      };

      shell = mkOption {
        type = types.package;
        default = pkgs.bashInteractive;
        description = ''
          The shell to use for the user.
        '';
      };
    };

    config = {
      user = {
        inherit (cfg) shell;
      };

      home-manager.config = {
        imports = let
          userHome = self + "/nix/homes/${cfg.name}";
          systemHome = self + "/nix/homes/${cfg.name}@droid";
          # hostName is usually not set in nix-on-droid like it is in nixos,
          # but we could use the droid configuration name if we pass it, or just use the base user.
          # For now, let's just import the base user home.
        in
          (optional (pathExists userHome) userHome) ++ (optional (pathExists systemHome) systemHome);

        home = {
          username = "nix-on-droid"; # The actual user in termux/nix-on-droid is always nix-on-droid
        };
      };
    };
  }
