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
        (lib.mapAttrs' (name: _value: {
            name = "build-nixos-${name}";
            value = {
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
                  name = "Magic Nix Cache";
                  uses = "DeterminateSystems/magic-nix-cache-action@main";
                  with_ = {
                    use-flakehub = false;
                  };
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
                  name = "Magic Nix Cache";
                  uses = "DeterminateSystems/magic-nix-cache-action@main";
                  with_ = {
                    use-flakehub = false;
                  };
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
                  name = "Magic Nix Cache";
                  uses = "DeterminateSystems/magic-nix-cache-action@main";
                  with_ = {
                    use-flakehub = false;
                  };
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
