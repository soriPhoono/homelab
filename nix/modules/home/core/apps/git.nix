{
  lib,
  config,
  ...
}: let
  cfg = config.core.apps.git;
in
  with lib; {
    options.core.apps.git = {
      enable = mkEnableOption "Enable git configurations";

      userName = mkOption {
        type = types.str;
        default = "";
        description = "The git username to use for this user";
        example = "john";
      };

      userEmail = mkOption {
        type = with types; nullOr str;
        description = "The email to use for git";
        default = null;
        example = "johnDoe@gmail.com";
      };

      projectsDir = mkOption {
        type = types.path;
        description = "The directory where git projects are stored";
        default = config.home.homeDirectory + "/Documents/Projects";
        example = "/run/media/john_doe/Projects";
      };

      extraIdentities = mkOption {
        type = with types;
          attrsOf (submodule {
            options = {
              name = mkOption {
                type = nullOr str;
                default = null;
                description = "The name to use for this identity (overrides global name)";
                example = "john_work";
              };
              directory = mkOption {
                type = str;
                description = "The directory of the group of projects for this identity";
                example = "Work";
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
            signingKey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
          };
          school = {
            directory = "School";
            name = "john_school";
            signingKey = "ssh-ed25519 AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
          };
        };
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.userName != "";
          message = "core.git.userName must be set.";
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
            user = mkMerge [
              {name = cfg.userName;}
              (mkIf config.core.email.enable {
                email =
                  if (config.accounts.email.accounts ? "git")
                  then config.accounts.email.accounts.git.address
                  else config.accounts.email.accounts.primary.address;
              })
              (mkIf (!config.core.email.enable && cfg.userEmail != null) {
                email = cfg.userEmail;
              })
            ];

            init.defaultBranch = "main";

            diff.algorithm = "histogram";

            help.autocorrect = "prompt";

            commit.verbose = true;
            pull.rebase = true;
            push = {
              default = "current";
              autoSetupRemote = true;
            };
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

        lazygit.enable = true;
      };
    };
  }
