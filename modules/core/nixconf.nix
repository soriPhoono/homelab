{ inputs, lib, ... }: {
  den = {
    default = {
      nixos = { config, ... }: {
        nix =
          let
            flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
          in
          {
            settings = {
              # download-buffer-size = 1073741824;

              # Enable flakes and new 'nix' command
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              # Opinionated: disable global registry
              flake-registry = "";

              trusted-users = config.users.groups.wheel.members;

              # Limit the number of cores used per build job to prevent OOM
              # during memory-intensive compilations (like browsers).
              max-jobs = 1;
              cores = 4;

              # Common substituters applicable to all systems
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };
            # Opinionated: disable channels
            channel.enable = false;

            # Opinionated: make flake registry and nix path match flake inputs
            registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
            nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
          };
        programs.nix-ld.enable = true;
      };
      homeManager = _: {
        nix =
          let
            flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
          in
          {
            settings = {
              # download-buffer-size = 1073741824;

              # Enable flakes and new 'nix' command
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              # Opinionated: disable global registry
              flake-registry = "";

              # Limit the number of cores used per build job to prevent OOM
              # during memory-intensive compilations (like browsers).
              max-jobs = 1;
              cores = 4;

              # Common substituters applicable to all systems
              substituters = [
                "https://cache.nixos.org"
                "https://nix-community.cachix.org"
              ];
              trusted-public-keys = [
                "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              ];
            };

            # Opinionated: make flake registry and nix path match flake inputs
            registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
            nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
          };
      };
    };
  };
}
