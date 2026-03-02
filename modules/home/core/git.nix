{
  lib,
  config,
  ...
}: let
  cfg = config.core.git;
in {
  options.core.git = {
    userName = lib.mkOption {
      type = lib.types.str;
      description = "The git username to use for this user";
      example = "john";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "The git email to use for this user";
      example = "john@gmail.com";
    };

    projectsDir = lib.mkOption {
      type = lib.types.path;
      description = "The directory where git projects are stored";
      default = config.home.homeDirectory + "/Documents/Projects";
      example = "/run/media/john_doe/Projects";
    };

    extraIdentities = lib.mkOption {
      type = with lib;
      with types;
        attrsOf (submodule {
          options = {
            directory = mkOption {
              type = str;
              description = "The directory of the group of projects for this identity";
              example = "Work";
            };
            name = mkOption {
              type = str;
              description = "The name to use for this identity";
              example = "john_work";
            };
            email = mkOption {
              type = str;
              description = "The email to use for this identity";
              example = "john_work@gmail.com";
            };
            signingKey = mkOption {
              type = str;
              description = "The SSH public key to use for signing commits with this identity";
              example = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
            };
          };
        });
      description = "A list of SSH identities to use for signing git commits, each attribute name is the key used for ssh key deployment.";
      default = {};
      example = {
        work = {
          directory = "Work";
          name = "john_work";
          email = "john_work@gmail.com";
          signingKey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        };
        school = {
          directory = "School";
          name = "john_school";
          email = "JohnDoe@abc.edu";
          signingKey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
        };
      };
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.userName != "";
        message = "core.git.userName must be set.";
      }
      {
        assertion = cfg.userEmail != "";
        message = "core.git.userEmail must be set.";
      }
    ];

    core.ssh.extraSSHKeys =
      lib.mapAttrs
      (_: identity: identity.signingKey)
      cfg.extraIdentities;

    programs = {
      git = {
        enable = true;

        signing = {
          format = "ssh";
          key = config.core.ssh.publicKey;
          signByDefault = true;
        };

        includes =
          lib.mapAttrsToList (_: identity: {
            condition = "gitdir:${cfg.projectsDir}/${identity.directory}/";
            contents.user = {
              inherit (identity) name email signingKey;
            };
          })
          cfg.extraIdentities;

        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };

          init.defaultBranch = "main";

          diff.algorithm = "histogram";

          help.autocorrect = "prompt";

          commit.verbose = true;
          push = {
            default = "current";
            autoSetupRemote = true;
          };
          pull.rebase = true;
          rebase.autosquash = true;
          rerere.enabled = true;

          merge.conflictStyle = "zdiff3";

          url = {
            "git@github.com:" = {
              insteadOf = ["github:" "gh:"];
            };
          };
        };
      };

      delta = {
        enable = true;
        enableGitIntegration = true;

        options = {
          line-numbers = true;
          side-by-side = true;
        };
      };
    };
  };
}
