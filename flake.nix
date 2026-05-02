{
  description = "A system flake for my homelab and personal devices";

  inputs = {
    templates.url = "github:soriPhoono/templates";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";

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

    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    nur,
    ...
  }: let
    readMeta = dir:
      if builtins.pathExists (dir + "/meta.json")
      then builtins.fromJSON (builtins.readFile (dir + "/meta.json"))
      else {};

    lib = nixpkgs.lib.extend (import ./nix/lib.nix);

    # --- System Support & Package Cache --- #
    systems = import inputs.systems;

    pkgsBatch = lib.genAttrs systems (system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = builtins.attrValues (import ./nix/overlays {inherit inputs lib;}
          // {
            nur = nur.overlays.default;
          });
      });

    # --- System Builder Parameters --- #
    homeManagerModules = with inputs; [
      self.homeModules.default
      sops-nix.homeManagerModules.sops
      stylix.homeModules.stylix
      noctalia.homeModules.default
    ];

    nixosModules = with inputs; [
      self.nixosModules.default
      nixos-facter-modules.nixosModules.facter
      disko.nixosModules.disko
      determinate.nixosModules.default
      comin.nixosModules.comin
      sops-nix.nixosModules.sops
      stylix.nixosModules.stylix
      nix-index-database.nixosModules.nix-index
      home-manager.nixosModules.home-manager
    ];

    # --- System Builders --- #

    # Standalone Home Manager Builder
    mkHome = username: homeName: let
      basePath = ./nix/homes + "/${username}";
      homePath = ./nix/homes + "/${username}@${homeName}";

      # Optimization: Short-circuit the filesystem check if this is just a base user
      hasBase = builtins.pathExists basePath;
      hasHome = homeName != "" && builtins.pathExists homePath;

      # Read meta from home first, then base, fallback to empty
      meta =
        if hasHome
        then readMeta homePath
        else if hasBase
        then readMeta basePath
        else {};

      systemArch = meta.system or "x86_64-linux";
      pkgs = pkgsBatch.${systemArch};
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs self;
        };
        modules =
          homeManagerModules
          ++ [
            {
              home = {
                inherit username;
                homeDirectory = lib.mkDefault (
                  if pkgs.stdenv.isDarwin
                  then "/Users/${username}"
                  else "/home/${username}"
                );
              };
            }
          ]
          ++ lib.optional hasBase (basePath + "/default.nix")
          ++ lib.optional hasHome (homePath + "/default.nix");
      };

    # Base NixOS System Builder
    mkSystem = hostName: let
      path = ./nix/systems/${hostName};
      meta = readMeta path;
      system = meta.system or "x86_64-linux";
      pkgs = pkgsBatch.${system};
    in
      lib.nixosSystem {
        inherit pkgs;
        specialArgs = {
          inherit inputs self;
        };
        modules =
          nixosModules
          ++ [
            {
              networking.hostName = hostName;

              home-manager = {
                sharedModules = homeManagerModules;
                backupFileExtension = "bak";
                useGlobalPkgs = true;
                useUserPackages = true;
                extraSpecialArgs = {
                  inherit inputs self;
                };
              };
            }
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
      inherit systems;

      agenix-shell = {
        identityPaths = [
          "$HOME/.ssh/id_ed25519"
        ];
        secrets = {
        };
      };

      perSystem = {
        pkgs,
        config,
        system,
        ...
      }: {
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit agenix-shell githubActions;
          };
        };

        # --- Configuration Builders --- #
        githubActions = import ./actions.nix {inherit self lib;};
        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};

        apps = {
          deploy-test-cluster = {
            type = "app";
            program = "${pkgs.writeShellApplication {
              name = "deploy-test-cluster";
              runtimeInputs = with pkgs; [
                k3d
                kubectl
                kubeseal
                kubernetes-helm
                fluxcd
              ];
              text = ''
                # Disable k3s-bundled Traefik; Flux installs Traefik from the official Helm chart (testing path).
                k3d cluster create test-cluster --k3s-arg '--disable=traefik@server:0'
              '';
            }}/bin/deploy-test-cluster";
          };
        };
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./nix/modules/nixos {inherit lib self;};
        homeModules = import ./nix/modules/home {inherit lib self;};

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs (hostName: _: mkSystem hostName) (lib.homelab.discover ./nix/systems);

        # All standalone homes in the /homes folder
        # Scans for <user> and <user>@<homeName>, combines them if both exist.
        homeConfigurations = let
          # Retrieve raw directory contents as attribute sets { "name" = "type"; }
          homesContent = builtins.readDir ./nix/homes;
          systemsContent = builtins.readDir ./nix/systems;

          # Optimization: Keep systems as an attribute set for O(1) lookups
          systemHosts = lib.filterAttrs (_n: type: type == "directory") systemsContent;

          # Single-pass evaluation: maps the directory name to { name, value } or drops it (null)
          processHomeDir = name: type:
            if type != "directory"
            then null
            else let
              parts = lib.splitString "@" name;
              username = lib.head parts;
              hostName =
                if lib.length parts > 1
                then lib.last parts
                else "";
            in
              # Optimization: Simplified boolean logic and O(1) existence check
              if hostName != "droid" && !(lib.hasAttr hostName systemHosts)
              then {
                inherit name;
                value = mkHome username hostName;
              }
              else null;
        in
          # Execute single pass, strip out skipped directories (nulls), and build the final set
          builtins.listToAttrs (
            builtins.filter (x: x != null) (
              lib.mapAttrsToList processHomeDir homesContent
            )
          );
      };
    };
}
