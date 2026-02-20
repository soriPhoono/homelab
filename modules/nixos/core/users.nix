{
  lib,
  pkgs,
  config,
  self,
  hostName,
  ...
}: let
  cfg = config.core;

  mkIdRangeOption = idName: let
    lowerIdName = lib.toLower idName;
  in
    lib.mkOption {
      type = with lib.types;
        listOf (submodule {
          options = {
            "start${idName}" = lib.mkOption {
              type = int;
              description = "The start ${lowerIdName} of the range.";
            };
            count = lib.mkOption {
              type = int;
              description = "The number of ${lowerIdName}s in the range.";
            };
          };
        });
      default = [];
      description = "The sub-${lowerIdName} ranges for the user.";
    };
in {
  options.core.users = with lib;
    mkOption {
      type = with types;
        attrsOf (submodule {
          options = {
            admin = mkOption {
              type = bool;
              default = false;
              description = "Whether the user should have admin privileges.";
              example = true;
            };

            hashedPassword = mkOption {
              type = nullOr str;
              default = null;
              description = "The password hash for the user";
              example = "$6$N9zTq2VII1RiqgFr$IO8lxVRPfDPoDs3qZIqlUtfhtLxx/iNO47hUcx2zbDGHZsw..1sy5k.6.HIxpwkAhDPI7jZnTXKaIKqwiSWZA0";
            };

            extraGroups = mkOption {
              type = listOf str;
              default = [];
              description = "Additional groups the user should belong to.";
              example = ["wheel" "docker"];
            };

            shell = mkOption {
              type = package;
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

            subUidRanges = mkIdRangeOption "Uid";

            subGidRanges = mkIdRangeOption "Gid";
          };
        });

      description = "List of users to create.";

      example = {
        john = {
          admin = true;
        };
      };
    };

  config = lib.mkIf (cfg.users != {}) {
    programs.fish.enable = lib.any (user: user.shell == pkgs.fish) (builtins.attrValues cfg.users);

    services.logind.settings.Login = {
      RuntimeDirectorySize = "25%";
    };

    users = {
      mutableUsers = false;

      extraUsers =
        lib.mapAttrs (name: user: {
          inherit (user) hashedPassword shell subUidRanges subGidRanges;
          isNormalUser = true;
          extraGroups = user.extraGroups ++ lib.optional user.admin "wheel";
          group = name;

          openssh.authorizedKeys.keys = lib.optional (user.publicKey != null) user.publicKey;
        })
        cfg.users;

      groups = lib.mapAttrs (_name: _: {}) cfg.users;
    };

    home-manager.users =
      lib.mapAttrs (username: user: {
        imports = let
          userHome = self + "/homes/${username}";
          hostHome = self + "/homes/${username}@${hostName}";
        in
          lib.optional (builtins.pathExists userHome) userHome
          ++ lib.optional (builtins.pathExists hostHome) hostHome;

        home = {
          inherit username;
        };

        core = {
          ssh.publicKey = lib.mkIf (user.publicKey != null) user.publicKey;
          shells.fish.enable = user.shell == pkgs.fish;
        };
      })
      cfg.users;
  };
}
