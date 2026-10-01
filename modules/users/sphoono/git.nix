{
  den.aspects.sphoono.homeManager = { config, ... }: {
    sops = {
      secrets = {
        "git/username" = { };
        "git/email" = { };
      };
      templates."git/email-includes".content = ''
        [user]
          name = ${config.sops.placeholder."git/username"}
          email = ${config.sops.placeholder."git/email"}
      '';
    };
    programs = {
      lazygit.enable = true;
      git = {
        enable = true;
        signing = {
          format = "ssh";
          key = "${config.home.homeDirectory}/.ssh/id_primary.pub";
          signByDefault = true;
        };
        includes = [
          {
            path = config.sops.templates."git/email-includes".path;
          }
        ];
        settings = {
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
              insteadOf = [
                "github:"
                "gh:"
              ];
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
