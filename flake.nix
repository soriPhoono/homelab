{
  description = "A system flake for my homelab and personal devices";

  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

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

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    agenix,
    ...
  }: let
    # Extend lib with our custom functions
    lib = nixpkgs.lib.extend (final: prev:
      (import ./nix/lib/default.nix {inherit inputs;}) final prev
      // {
        inherit (inputs.home-manager.lib) hm;
      });

    # --- System Support & Package Cache --- #
    supportedSystems = import inputs.systems;
    pkgsFor = lib.genAttrs supportedSystems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = builtins.attrValues self.overlays;
      });

    # --- System Builder Parameters --- #
    homeManagerModules = with inputs; [
      self.homeModules.default
      sops-nix.homeManagerModules.sops
      stylix.homeModules.stylix
      nvf.homeManagerModules.default
      noctalia.homeModules.default
      ({config, ...}: {
        home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
      })
    ];

    nixosModules = system:
      with inputs; [
        self.nixosModules.default
        home-manager.nixosModules.home-manager
        nixos-facter-modules.nixosModules.facter
        disko.nixosModules.disko
        determinate.nixosModules.default
        sops-nix.nixosModules.sops
        comin.nixosModules.comin
        nix-index-database.nixosModules.nix-index
        stylix.nixosModules.stylix
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs self lib;
              nvimConfigurations = self.nvimConfigurations.${system};
            };
            sharedModules = homeManagerModules;
            backupFileExtension = "bak";
          };
        }
      ];

    # --- System Builders --- #

    # Standalone Home Manager Builder
    mkHome = username: homeName: let
      basePath = ./nix/homes + "/${username}";
      homePath = ./nix/homes + "/${username}@${homeName}";

      # Determine if paths exist
      hasBase = builtins.pathExists basePath;
      hasHome = builtins.pathExists homePath;

      # Read meta from home first, then base, fallback to empty
      meta =
        if hasHome
        then lib.readMeta homePath
        else if hasBase
        then lib.readMeta basePath
        else {};

      systemArch = meta.system or "x86_64-linux";
      pkgs = pkgsFor.${systemArch};
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs self lib;
          nvimConfigurations = self.nvimConfigurations.${systemArch};
        };
        modules =
          [
            {
              home = {
                inherit username;
              };
            }
          ]
          ++ homeManagerModules
          ++ lib.optional hasBase (basePath + "/default.nix")
          ++ lib.optional hasHome (homePath + "/default.nix");
      };

    # Base NixOS System Builder
    mkSystem = hostName: path: let
      meta = lib.readMeta path;
      systemArch = meta.system or "x86_64-linux";
      pkgs = pkgsFor.${systemArch};
    in
      lib.nixosSystem {
        inherit pkgs;
        specialArgs = {
          inherit inputs self lib;
        };
        modules =
          (nixosModules systemArch)
          ++ [
            {
              networking.hostName = hostName;
            }
            path
          ];
      };

    # Standalone Neovim Builder
    mkNeovim = system: path: let
      pkgs = pkgsFor.${system};
    in
      inputs.nvf.lib.neovimConfiguration {
        inherit pkgs;
        modules = [
          path
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
      systems = supportedSystems;

      agenix-shell = {
        identityPaths = [
          "$HOME/.ssh/id_ed25519"
        ];
        secrets = {};
      };

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
            inherit (config) pre-commit agenix-shell githubActions;
          };
        };

        checks = let
          evalSystems = lib.mapAttrs' (name: conf: {
            name = "system-eval-${name}";
            value = conf.config.system.build.toplevel;
          }) (lib.filterAttrs (_name: conf: conf.pkgs.stdenv.hostPlatform.system == system) self.nixosConfigurations);

          # Evaluation checks for all homes matching this system
          evalHomes = lib.mapAttrs' (name: conf: {
            name = "home-eval-${name}";
            value = conf.activationPackage;
          }) (lib.filterAttrs (_name: conf: conf.pkgs.stdenv.hostPlatform.system == system) self.homeConfigurations);
        in
          evalSystems // evalHomes;

        packages = let
          customPkgs = import ./nix/pkgs {
            inherit
              inputs
              lib
              pkgs
              self
              ;
          };
        in
          customPkgs;

        # --- Configuration Builders --- #

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
        githubActions = import ./actions.nix {inherit self lib;};
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./nix/modules/nixos {inherit lib self;};
        homeModules = import ./nix/modules/home {inherit lib self;};

        # Overlay Exports
        overlays = with inputs; ((import ./nix/overlays {inherit self inputs lib;})
          // {
            nur = nur.overlays.default;
          });

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs mkSystem (lib.discover ./nix/systems);

        # All standalone homes in the /homes folder
        # Scans for <user> and <user>@<homeName>, combines them if both exist.
        homeConfigurations = let
          homeDirs = lib.attrNames (lib.filterAttrs (_n: v: v == "directory") (builtins.readDir ./nix/homes));
          hostDirs = builtins.readDir ./nix/systems;

          # Filter for base homes (no @) and standalone homes (user@host where systems/host doesn't exist)
          validHomeNames =
            lib.filter (
              name: let
                parts = lib.splitString "@" name;
                hostName =
                  if lib.length parts > 1
                  then lib.last parts
                  else "";
              in
                hostName == "" || !(hostDirs ? ${hostName})
            )
            homeDirs;

          # Helper to call mkHome with split username and homeName
          mkHomeConfig = name: let
            parts = lib.splitString "@" name;
            username = lib.head parts;
            homeName =
              if lib.length parts > 1
              then lib.last parts
              else "";
          in
            mkHome username homeName;
        in
          lib.genAttrs validHomeNames mkHomeConfig;

        # All standalone Neovim configurations
        nvimConfigurations = lib.genAttrs supportedSystems (
          system:
            lib.mapAttrs
            (_name: path: (mkNeovim system path).neovim) ((import ./nix/nvim) {
              inherit lib;
            })
        );

        # All templates in the /templates folder
        templates =
          lib.mapAttrs (name: _: let
            path = ./nix/templates + "/${name}";
          in {
            inherit path;
            inherit ((import "${path}/flake.nix")) description;
          }) (
            lib.filterAttrs (
              name: type: type == "directory" && builtins.pathExists (./nix/templates + "/${name}/flake.nix")
            ) (builtins.readDir ./nix/templates)
          );
      };
    };
}
