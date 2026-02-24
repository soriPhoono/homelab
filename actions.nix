{
  self,
  lib,
  ...
}: {
  enable = true;

  workflows = {
    ci = {
      name = "CI";
      on = {
        pullRequest = {};
      };
      permissions = {
        contents = "write";
      };
      jobs =
        {
          fmt = {
            runsOn = "ubuntu-latest";
            steps = [
              {
                name = "Checkout code";
                uses = "actions/checkout@v4";
                with_ = {
                  ref = "\$\{\{github.head_ref || github.ref\}\}";
                };
              }
              {
                name = "Setup Nix";
                uses = "DeterminateSystems/nix-installer-action@main";
              }
              {
                name = "Format code";
                run = "nix fmt";
              }
              {
                name = "Commit and push";
                run = ''
                  git config --global user.name "github-actions[bot]"
                  git config --global user.email "github-actions[bot]@users.noreply.github.com"
                  git commit -am "style: format code with nix fmt" || echo "No changes to commit"
                  git push
                '';
              }
            ];
          };
        }
        // (lib.mapAttrs' (name: _value: {
            name = "build-nixos-${name}";
            value = {
              needs = ["fmt"];
              runsOn = "ubuntu-latest";
              steps = [
                {
                  name = "Checkout code";
                  uses = "actions/checkout@v4";
                }
                {
                  name = "Setup Nix";
                  uses = "DeterminateSystems/nix-installer-action@main";
                }
                {
                  name = "Build";
                  run = "nix build .#nixosConfigurations.${name}.config.system.build.toplevel";
                }
              ];
            };
          })
          self.nixosConfigurations)
        // (lib.mapAttrs' (name: _value: {
            name = "build-home-${name}";
            value = {
              needs = ["fmt"];
              runsOn = "ubuntu-latest";
              steps = [
                {
                  name = "Checkout code";
                  uses = "actions/checkout@v4";
                }
                {
                  name = "Setup Nix";
                  uses = "DeterminateSystems/nix-installer-action@main";
                }
                {
                  name = "Build";
                  run = "nix build .#homeConfigurations.${name}.activationPackage";
                }
              ];
            };
          })
          self.homeConfigurations)
        // (lib.mapAttrs' (name: _value: {
            name = "build-droid-${name}";
            value = {
              needs = ["fmt"];
              runsOn = "ubuntu-24.04-arm";
              steps = [
                {
                  name = "Checkout code";
                  uses = "actions/checkout@v4";
                }
                {
                  name = "Setup Nix";
                  uses = "DeterminateSystems/nix-installer-action@main";
                }
                {
                  name = "Build";
                  run = "nix build --impure .#nixOnDroidConfigurations.${name}.activationPackage";
                }
              ];
            };
          })
          self.nixOnDroidConfigurations);
    };
  };
}
