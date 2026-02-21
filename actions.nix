{
  perSystem = _: {
    githubActions = {
      enable = true;

      workflows = {
        # --- Update Flake Lock ---
        update-flake-lock = {
          name = "Update flake.lock";

          on = {
            workflowDispatch = {};
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

        # --- Build Installer ISO ---
        build-installer-iso = {
          name = "Build Installer ISO";

          on = {
            push = {
              branches = ["main"];
              paths = ["pkgs/installer/version.nix"];
            };
            workflowDispatch = {};
          };

          permissions = {
            contents = "write";
          };

          jobs.build-iso = {
            runsOn = "ubuntu-latest";
            steps = [
              {
                uses = "actions/checkout@v4";
              }
              {
                uses = "jlumbroso/free-disk-space@main";
                with_ = {
                  tool-cache = true;
                  android = true;
                  dotnet = true;
                  haskell = true;
                  large-packages = true;
                  docker-images = true;
                  swap-storage = false;
                };
              }
              {
                uses = "DeterminateSystems/nix-installer-action@main";
              }
              {
                name = "Read installer version";
                id = "version";
                run = ''
                  VERSION=$(nix eval --raw --file pkgs/installer/version.nix)
                  echo "version=$VERSION" >> "$GITHUB_OUTPUT"
                  echo "Installer version: $VERSION"
                '';
              }
              {
                name = "Build installer ISO";
                run = "nix build .#packages.x86_64-linux.installer --out-link result-iso";
              }
              {
                name = "Locate ISO file";
                id = "iso";
                run = ''
                  ISO=$(find result-iso/ -name '*.iso' -type f | head -1)
                  echo "path=$ISO" >> "$GITHUB_OUTPUT"
                  echo "Found ISO: $ISO"
                '';
              }
              {
                name = "Upload installer ISO artifact";
                uses = "actions/upload-artifact@v4";
                with_ = {
                  name = "installer-iso";
                  path = "\${{ steps.iso.outputs.path }}";
                  retention-days = 5;
                  compression-level = 0;
                };
              }
              {
                name = "Create GitHub Release";
                uses = "softprops/action-gh-release@v2";
                with_ = {
                  tag_name = "installer-v\${{ steps.version.outputs.version }}";
                  name = "Installer v\${{ steps.version.outputs.version }}";
                  body = "Automated installer ISO build for version \${{ steps.version.outputs.version }}.";
                  files = "\${{ steps.iso.outputs.path }}";
                  make_latest = "true";
                };
              }
            ];
          };
        };
      };
    };
  };
}
