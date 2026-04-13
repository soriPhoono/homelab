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
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.userName != "";
          message = "core.git.userName must be set.";
        }
      ];

      programs = {
        lazygit.enable = true;

        git = {
          enable = true;

          signing = {
            format = "ssh";
            key = config.core.ssh.publicKey;
            signByDefault = true;
          };

          settings = {
            user = {
              name = cfg.userName;
              email =
                if (config.accounts.email.accounts ? "git")
                then config.accounts.email.accounts.git.address
                else config.accounts.email.accounts.primary.address;
            };

            init.defaultBranch = "main";
            diff.algorithm = "histogram";
            help.autocorrect = "prompt";
            commit.verbose = true;
            pull.rebase = true;
            rebase.autosquash = true;
            rerere.enabled = true;
            merge.conflictStyle = "zdiff3";

            push = {
              default = "current";
              autoSetupRemote = true;
            };

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
