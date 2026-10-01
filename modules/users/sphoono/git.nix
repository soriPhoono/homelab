{
  den.aspects.sphoono.homeManager =
    { config, lib, ... }:
    let
      email = "96075107+soriPhoono@users.noreply.github.com";
      publicKey = lib.fileContents ./assets/id_primary.pub;
    in
    {
      programs = {
        lazygit.enable = true;
        git = {
          enable = true;
          signing = {
            format = "ssh";
            key = "${config.home.homeDirectory}/.ssh/id_primary.pub";
            signByDefault = true;
            allowedSigners = "${email} ${publicKey}";
          };
          settings = {
            user = {
              name = "soriphoono";
              inherit email;
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
