{
  description = "A system flake for my homelab and personal devices";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://numtide.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigyw8tcMo="
    ];
    allow-import-from-derivation = "true";
  };

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

    nix-on-droid = {
      url = "github:nix-community/nix-on-droid/master";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    agenix,
    nixtest,
    nix-on-droid,
    ...
  }: let
    # Extend lib with our custom functions
    lib = nixpkgs.lib.extend (final: prev:
      (import ./lib/default.nix {inherit inputs;}) final prev
      // {
        inherit (inputs.home-manager.lib) hm;
      });

    # --- System Builder Parameters --- #
    homeManagerModules = with inputs; [
      self.homeModules.default
      sops-nix.homeManagerModules.sops
      nvf.homeManagerModules.default
      mcps.homeManagerModules.gemini-cli
      mcps.homeManagerModules.claude
      mcps.homeManagerModules.antigravity
    ];

    droidModules = [
      self.droidModules.default
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "bak";
        };
      }
    ];

    nixosModules = with inputs; [
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
          startAsUserService = true;
          extraSpecialArgs = {inherit inputs self lib;};
          sharedModules = homeManagerModules;
          backupFileExtension = "bak";
        };
      }
    ];

    # --- System Builders --- #

    # Standalone Home Manager Builder
    mkHome = username: path: let
      meta = lib.readMeta path;
      systemArch = meta.system or "x86_64-linux";
      pkgs = import nixpkgs {
        system = systemArch;
        config.allowUnfree = true;
      };
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs self lib;};
        modules =
          homeManagerModules
          ++ [
            (path + "/default.nix")
            {
              nixpkgs = {
                config.allowUnfree = true;
                overlays = builtins.attrValues self.overlays;
              };
              home = {
                inherit username;
                homeDirectory = lib.mkDefault "/home/${username}";
                stateVersion = lib.mkDefault "24.11";
              };
            }
          ];
      };

    # Nix-on-Droid Builder
    mkDroid = _name: path: let
      meta = lib.readMeta path;
      systemArch = meta.system or "aarch64-linux";
      pkgs = import nixpkgs {
        system = systemArch;
        config.allowUnfree = true;
        overlays = builtins.attrValues self.overlays;
      };
    in
      nix-on-droid.lib.nixOnDroidConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs self lib;};
        modules =
          droidModules
          ++ [
            (path + "/default.nix")
            {
              home-manager = {
                useGlobalPkgs = true;
                backupFileExtension = "bak";
                extraSpecialArgs = {inherit inputs self lib;};
                sharedModules = homeManagerModules;
                config = {
                  imports = lib.optional (builtins.pathExists (path + "/home.nix")) (path + "/home.nix");
                };
              };
            }
          ];
      };

    # Base NixOS System Builder
    mkSystem = hostName: path: let
      meta = lib.readMeta path;
      systemArch = meta.system or "x86_64-linux";
    in
      lib.nixosSystem {
        system = systemArch;
        specialArgs = {
          inherit inputs self lib hostName;
        };
        modules =
          nixosModules
          ++ [
            (path + "/default.nix")
            {
              networking.hostName = hostName;
            }
          ];
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
        pkgs,
        config,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          overlays = [
            (_: _: {
              agenix = agenix.packages.${system}.default;
            })
          ];
          config.allowUnfree = true;
        };

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit;
          };
        };

        checks =
          lib.discoverTests {
            inherit pkgs inputs self;
            inherit (inputs) nixtest;
          }
          ./tests;

        packages = import ./pkgs {
          inherit
            inputs
            lib
            pkgs
            self
            ;
        };

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./modules/nixos {inherit lib self;};
        droidModules = import ./modules/droid {inherit lib self;};
        homeModules = import ./modules/home {inherit lib self;};

        # Overlay Exports
        overlays = with inputs; ((import ./overlays {inherit lib self;})
          // {
            nur = nur.overlays.default;
            mcps = mcps.overlays.default;
          });

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs mkSystem (lib.discover ./systems);

        # All nix-on-droid configurations in the /droids folder
        nixOnDroidConfigurations = lib.mapAttrs mkDroid (lib.discover ./droids);

        # All standalone homes in the /homes folder
        homeConfigurations = lib.mapAttrs mkHome (lib.discover ./homes);

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
