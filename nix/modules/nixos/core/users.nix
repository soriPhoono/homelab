{
  self,
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.core;
in
with lib;
{
  options.core.users = mkOption {
    type =
      with types;
      attrsOf (submodule {
        options = {
          description = mkOption {
            type = str;
            description = "Account description for the user.";
            example = "Primary administrator";
          };

          admin = mkEnableOption "Enable admin privileges for the user";
          secrets = mkOption {
            type = types.bool;
            default = false;
            description = "Whether the user should have admin privileges.";
            example = true;
          };

          shell = mkOption {
            type = with types; nullOr package;
            default = pkgs.bashInteractive;
            description = "The shell for the user.";
            example = pkgs.zsh;
          };

          publicKey = mkOption {
            type = nullOr str;
            default = null;
            description = "The public key for the user.";
            example = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...";
          };

          hashedPassword = mkOption {
            type = nullOr str;
            default = null;
            description = "The password hash for the user";
            example = "$6$N9zTq2VII1RiqgFr$IO8lxVRPfDPoDs3qZIqlUtfhtLxx/iNO47hUcx2zbDGHZsw..1sy5k.6.HIxpwkAhDPI7jZnTXKaIKqwiSWZA0";
          };

          extraGroups = mkOption {
            type = listOf str;
            default = [ ];
            description = "Additional groups the user should belong to.";
            example = [
              "wheel"
              "docker"
            ];
          };
        };
      });

    description = "List of users to create.";
    default = { };

    example = {
      john = {
        admin = true;
      };
    };
  };

  config = mkIf (cfg.users != { }) {
    assertions = mapAttrsToList (name: user: {
      assertion = user.hashedPassword != null || user.publicKey != null;
      message = "At least one authentication method must be present for user ${name}.";
    }) cfg.users;

    programs.fish.enable = any (user: user.shell == pkgs.fish) (attrValues cfg.users);

    services.logind.settings.Login = {
      RuntimeDirectorySize = "25%";
    };

    users = {
      mutableUsers = false;

      extraUsers = mapAttrs (name: user: {
        inherit (user) hashedPassword shell;
        isNormalUser = true;
        extraGroups = user.extraGroups ++ optional user.admin "wheel";
        group = name;

        description = mkIf (user.description != null) user.description;
        openssh.authorizedKeys.keys = optional (user.publicKey != null) user.publicKey;
      }) cfg.users;

      groups = mapAttrs (_name: _: { }) cfg.users;
    };

    home-manager.users = mapAttrs (username: user: {
      imports =
        let
          userHome = self + "/nix/homes/${username}";
          hostHome = self + "/nix/homes/${username}@${config.networking.hostName}";
        in
        optional (pathExists userHome) userHome ++ optional (pathExists hostHome) hostHome;

      home = {
        inherit username;
        homeDirectory = "/home/${username}";
      };

      core = {
        ssh.publicKey = mkIf (user.publicKey != null) user.publicKey;
        shells.fish.enable = user.shell == pkgs.fish;
      };
    }) cfg.users;
  };
}
