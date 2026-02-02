{
  lib,
  pkgs,
  config,
  ...
}: let
  cfg = config.core;
in {
  options.core.users = with lib;
    mkOption {
      type = with types;
        attrsOf (submodule {
          options = {
            hashedPassword = mkOption {
              type = str;
              description = "The password hash for the user";
              example = "$6$N9zTq2VII1RiqgFr$IO8lxVRPfDPoDs3qZIqlUtfhtLxx/iNO47hUcx2zbDGHZsw..1sy5k.6.HIxpwkAhDPI7jZnTXKaIKqwiSWZA0";
            };

            admin = mkOption {
              type = bool;
              default = false;
              description = "Whether the user should have admin privileges.";
              example = true;
            };

            extraGroups = mkOption {
              type = listOf str;
              default = [];
              description = "Additional groups the user should belong to.";
              example = ["wheel" "docker"];
            };

            shell = with pkgs;
              mkOption {
                type = package;
                default = bashInteractive;
                description = "The shell for the user.";
                example = zsh;
              };

            publicKey = mkOption {
              type = nullOr str;
              default = null;
              description = "The public key for the user.";
              example = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...";
            };

            subUidRanges = mkOption {
              type = with types;
                listOf (submodule {
                  options = {
                    startUid = mkOption {
                      type = int;
                      description = "The start uid of the range.";
                    };
                    count = mkOption {
                      type = int;
                      description = "The number of uids in the range.";
                    };
                  };
                });
              default = [];
              description = "The sub-uid ranges for the user.";
            };

            subGidRanges = mkOption {
              type = with types;
                listOf (submodule {
                  options = {
                    startGid = mkOption {
                      type = int;
                      description = "The start gid of the range.";
                    };
                    count = mkOption {
                      type = int;
                      description = "The number of gids in the range.";
                    };
                  };
                });
              default = [];
              description = "The sub-gid ranges for the user.";
            };
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
        lib.mapAttrs (_name: user: {
          inherit (user) hashedPassword extraGroups shell subUidRanges subGidRanges;

          openssh.authorizedKeys.keys = lib.optional (user.publicKey != null) user.publicKey;
        })
        cfg.users;
    };

    home-manager.users =
      lib.mapAttrs (_: user: {
        core = {
          ssh.publicKey = lib.mkIf (user.publicKey != null) user.publicKey;
          shells.fish.enable = user.shell == pkgs.fish;
        };
      })
      cfg.users;
  };
}
