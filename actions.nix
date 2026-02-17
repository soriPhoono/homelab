{
  perSystem = _: {
    githubActions = {
      enable = true;

      workflows = {
        # --- Update Flake Lock ---
        update-flake-lock = {
          name = "Update flake.lock";

          on = {
            workflow_dispatch = {};
            schedule = [{cron = "0 0 * * 0";}]; # Weekly on Sunday at midnight
          };

          permissions = {
            contents = "write";
            pull-requests = "write";
          };

          jobs.update-lock = {
            runsOn = "ubuntu-latest";
            steps = [
              {
                uses = "actions/checkout@v4";
              }
              {
                uses = "DeterminateSystems/nix-installer-action@main";
              }
              {
                uses = "DeterminateSystems/update-flake-lock@main";
                with_ = {
                  inputs = "nixpkgs home-manager nix-on-droid flake-parts systems";
                  commit-msg = "chore(flake): update inputs";
                  pr-title = "chore(flake): update inputs";
                  pr-labels = "dependencies,automated";
                  pr-body = "Automated update of flake inputs via github-actions-nix.";
                  sign-commits = "true";
                };
              }
            ];
          };
        };

        # --- CI Checks ---
        ci = {
          name = "CI";

          on = ["push" "pull_request"];

          jobs.checks = {
            runsOn = "ubuntu-latest";
            steps = [
              {
                uses = "actions/checkout@v4";
              }
              {
                uses = "DeterminateSystems/nix-installer-action@main";
              }
              {
                name = "Run flake checks";
                run = "nix flake check --all-systems";
              }
            ];
          };
        };
      };
    };
  };
}
