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
                  uses = "DeterminateSystems/nix-installer-action@v14";
                }
                {
                  name = "Magic Nix Cache";
                  uses = "DeterminateSystems/magic-nix-cache-action@v8";
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
                  uses = "DeterminateSystems/nix-installer-action@v14";
                }
                {
                  name = "Magic Nix Cache";
                  uses = "DeterminateSystems/magic-nix-cache-action@v8";
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
          self.homeConfigurations);
    };
  };
}
