_: {
  githubActions = {
    enable = true;

    workflows = {
      # Generate a workflow to update flake inputs
      update-flake-lock = {
        enable = true;
        frequency = "weekly"; # or cron syntax "0 0 * * 0"
        inputs = [
          "nixpkgs"
          "home-manager"
          "nix-on-droid"
          "flake-parts"
          "systems"
        ];
        title = "Update flake.lock";
        body = "Automated update of flake inputs via github-actions-nix.";
        sign-commits = true;
        commit-msg = "chore(flake): update inputs";
        pr-title = "chore(flake): update inputs";
        pr-labels = ["dependencies" "automated"];
      };

      # Generate a checks workflow (ci.yml)
      checks = {
        enable = true;
        # Checks to run. By default it runs all checks in `checks` output.
        # We rely on our `checks` output being comprehensive.
      };
    };
  };
}
