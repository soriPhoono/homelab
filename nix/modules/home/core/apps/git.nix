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

      signingProvider = mkOption {
        type = types.enum ["ssh" "gpg"];
        default = "ssh";
        description = ''
          Which signing provider to use for git commits and tags.
          "gpg" requires core.gpg to be enabled on the same home configuration.
        '';
      };

      signingKey = mkOption {
        type = types.str;
        default = "primary";
        description = ''
          Name of the SSH key from core.ssh.publicKeys to use for commit signing.
          Only used when signingProvider is "ssh".
        '';
      };
    };

    config = mkIf cfg.enable {
      assertions = [
        {
          assertion = cfg.userName != "";
          message = "core.git.userName must be set.";
        }
      ];

      warnings = optionals (cfg.signingProvider == "gpg" && !((config.core.gpg or {}).enable or false)) [
        "core.apps.git.signingProvider is set to 'gpg' but core.gpg.enable is not set. Git signing will fall back to SSH. Either enable core.gpg or set signingProvider to 'ssh'."
      ];

      programs = {
        lazygit.enable = true;

        git = {
          enable = true;

          signing = let
            useGpg = cfg.signingProvider == "gpg" && ((config.core.gpg or {}).enable or false);
            gpgFingerprint = ((config.core.gpg or {}).identities or {}).${cfg.signingKey}.keyFingerprint or "";
            sshSigningKey = config.core.ssh.publicKeys.${cfg.signingKey} or "";
          in {
            format =
              if useGpg
              then "openpgp"
              else "ssh";
            key =
              if useGpg
              then gpgFingerprint
              else sshSigningKey;
            signByDefault = true;
          };

          settings = {
            user = {
              name = cfg.userName;
              email =
                if (builtins.hasAttr "git" config.accounts.email.accounts)
                then config.accounts.email.accounts.git.address
                else if (builtins.hasAttr "primary" config.accounts.email.accounts)
                then config.accounts.email.accounts.primary.address
                else throw "No email address found for user ${cfg.userName}";
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
