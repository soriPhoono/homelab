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
  };
}
