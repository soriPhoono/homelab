{
  description = "A system flake for my homelab and personal devices";

  inputs = {
    systems.url = "github:nix-systems/default";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixtest = {
      url = "github:jetify-com/nixtest";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-shell = {
      url = "github:aciceri/agenix-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    github-actions-nix = {
      url = "github:synapdeck/github-actions-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    comin = {
      url = "github:nlewo/comin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };

    mcps = {
      url = "github:soriphoono/mcps.nix";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    agenix,
    nixtest,
    ...
  }: let
    inherit (nixpkgs) lib;

    # Dynamic Discovery: Reads a directory and returns an attrset of { name = path; }
    # including directories with default.nix and standalone .nix files.
    discover = dir:
      lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = dir + "/${name}";
      }) (
        lib.filterAttrs (
          name: type:
            (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
            || (type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
        ) (builtins.readDir dir)
      );

    # Discovery for Tests: specifically just find .nix files in tests/
    discoverTests = args: dir:
      lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = import (dir + "/${name}") args;
      }) (
        lib.filterAttrs (
          name: type:
            type == "regular" && lib.hasSuffix ".nix" name
        ) (builtins.readDir dir)
      );

    # Metadata Reader: Reads meta.json from a path
    readMeta = path:
      if builtins.pathExists (path + "/meta.json")
      then builtins.fromJSON (builtins.readFile (path + "/meta.json"))
      else {};

    # --- System Builder Parameters --- #
    homeManagerModules = with inputs; [
      self.homeModules.default
      sops-nix.homeManagerModules.sops
      nvf.homeManagerModules.default
      mcps.homeManagerModules.gemini-install
      mcps.homeManagerModules.claude
    ];

    nixosModules = hostName:
      with inputs; [
        self.nixosModules.default
        home-manager.nixosModules.home-manager
        nixos-facter-modules.nixosModules.facter
        disko.nixosModules.disko
        determinate.nixosModules.default
        lanzaboote.nixosModules.lanzaboote
        sops-nix.nixosModules.sops
        comin.nixosModules.comin
        nix-index-database.nixosModules.nix-index
        {
          nixpkgs.overlays = builtins.attrValues self.overlays;
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {inherit inputs self hostName;};
            sharedModules = homeManagerModules;
            backupFileExtension = "backup";
          };
        }
      ];

    # --- System Builders --- #

    # Base NixOS System Builder
    mkSystem = hostName: path: let
      meta = readMeta path;
      systemArch = meta.system or "x86_64-linux";
    in
      lib.nixosSystem {
        system = systemArch;
        specialArgs = {
          inherit inputs self hostName;
        };
        modules =
          (nixosModules hostName)
          ++ [
            (path + "/default.nix")
          ];
      };

    # Standalone Home Manager Builder
    mkHome = name: path: let
      meta = readMeta path;
      systemArch = meta.system or "x86_64-linux";
      pkgs = import nixpkgs {
        system = systemArch;
        config.allowUnfree = true;
        overlays = builtins.attrValues self.overlays;
      };
      # Extract username and host from folders named "user@host" or just "user"
      nameParts = lib.splitString "@" name;
      username = lib.head nameParts;
      hostName =
        if lib.length nameParts > 1
        then lib.last nameParts
        else "generic";
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs self hostName;};
        modules =
          [
            (path + "/default.nix")
            {
              nixpkgs.overlays = builtins.attrValues self.overlays;
              home = {
                inherit username;
                homeDirectory = lib.mkDefault "/home/${username}";
                stateVersion = lib.mkDefault "24.11";
              };
            }
          ]
          ++ homeManagerModules;
      };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = with inputs; [
        agenix-shell.flakeModules.default
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
        github-actions-nix.flakeModule
      ];

      # Supported systems for devShells/checks
      systems = import inputs.systems;

      agenix-shell.secrets = (import ./secrets.nix {inherit lib;}).agenix-shell-secrets;

      perSystem = {
        config,
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (_: _: {
              agenix = agenix.packages.${system}.default;
            })
          ];
          config.allowUnfree = true;
        };
      in {
        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit;
          };
        };

        packages = import ./pkgs {
          inherit
            inputs
            lib
            pkgs
            self
            ;
        };

        checks =
          discoverTests {
            inherit pkgs inputs self;
            inherit (inputs) nixtest;
          }
          ./tests;

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./modules/nixos {inherit lib self;};
        homeModules = import ./modules/home {inherit lib self;};

        # Overlay Exports
        overlays = with inputs; ((import ./overlays {inherit lib self;})
          // {
            nur = nur.overlays.default;
            mcps = mcps.overlays.default;
          });

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs mkSystem (discover ./systems);

        # All standalone homes in the /homes folder
        homeConfigurations = lib.mapAttrs mkHome (discover ./homes);

        # All templates in the /templates folder
        templates =
          lib.mapAttrs (name: _: let
            path = ./templates + "/${name}";
          in {
            inherit path;
            inherit ((import "${path}/flake.nix")) description;
          }) (
            lib.filterAttrs (
              name: type: type == "directory" && builtins.pathExists (./templates + "/${name}/flake.nix")
            ) (builtins.readDir ./templates)
          );
      };
    };
}
