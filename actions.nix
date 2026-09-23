{
  self,
  lib,
  ...
}: let
  # Common setup steps shared across all build jobs
  setupSteps = [
    {
      name = "Checkout code";
      uses = "actions/checkout@v4";
    }
    {
      name = "Setup Nix";
      uses = "DeterminateSystems/nix-installer-action@v14";
    }
    {
      name = "Cachix cache";
      uses = "cachix/cachix-action@v17";
      with_ = {
        name = "homelab";
        # Falls back to pull-only if secrets are not configured
        authToken = "\${{ secrets.CACHIX_AUTH_TOKEN }}";
        signingKey = "\${{ secrets.CACHIX_SIGNING_KEY }}";
      };
    }
    {
      name = "Magic Nix Cache";
      uses = "DeterminateSystems/magic-nix-cache-action@v8";
      with_ = {
        use-flakehub = false;
      };
    }
  ];
in {
  enable = true;

  workflows = {
    ci = {
      name = "CI";
      on = {
        pullRequest = {};
      };
      permissions = {
        contents = "read";
        id-token = "write";
      };

      jobs =
        # ── Evaluation check (fast gate) ────────────────────
        # Runs first; all build jobs wait for this to pass.
        # Catches evaluation errors in seconds before spending
        # time on expensive builds.
        {
          evaluate = {
            runsOn = "ubuntu-24.04";
            steps =
              setupSteps
              ++ [
                {
                  name = "Check flake";
                  run = "nix flake check --all-systems";
                }
              ];
          };
        }
        # ── NixOS system builds ─────────────────────────────
        // (lib.mapAttrs' (name: _value: {
            name = "build-nixos-${name}";
            value = {
              runsOn = "ubuntu-24.04";
              needs = ["evaluate"];
              steps =
                setupSteps
                ++ [
                  {
                    name = "Build";
                    run = "nix build .#nixosConfigurations.${name}.config.system.build.toplevel";
                  }
                ];
            };
          })
          self.nixosConfigurations)
        # ── Standalone home-manager builds ──────────────────
        // (lib.mapAttrs' (name: _value: {
            name = "build-home-${name}";
            value = {
              runsOn = "ubuntu-24.04";
              needs = ["evaluate"];
              steps =
                setupSteps
                ++ [
                  {
                    name = "Build";
                    run = "nix build .#homeConfigurations.${name}.activationPackage";
                  }
                ];
            };
          })
          self.homeConfigurations);
    };

    # ── Scheduled flake.lock updates ──────────────────────
    # Mirrors the previous hand-written update-flake-lock.yml
    # workflow, now driven from actions.nix like everything else.
    "update-flake-lock" = {
      name = "Update flake.lock";
      on = {
        schedule = [
          {cron = "0 0 * * 0";}
        ];
        workflowDispatch = {};
      };
      permissions = {
        contents = "write";
        id-token = "write";
        issues = "write";
        pull-requests = "write";
      };
      concurrency = {
        group = "update-flake-lock";
        cancelInProgress = true;
      };

      jobs = {
        "update-flake-lock" = {
          runsOn = "ubuntu-24.04";
          steps = [
            {
              name = "Checkout code";
              uses = "actions/checkout@v6";
            }
            {
              name = "Setup Nix";
              uses = "DeterminateSystems/determinate-nix-action@v3.17.3";
            }
            {
              name = "Update flake.lock";
              uses = "DeterminateSystems/update-flake-lock@v28";
              with_ = {
                token = "\${{ github.token }}";
                pr-title = "chore(deps): update flake.lock";
                pr-labels = "dependencies\nautomated";
              };
            }
          ];
        };
      };
    };
  };
}
