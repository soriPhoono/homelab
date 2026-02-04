{
  description = "A system flake for my homelab and personal devices";

  inputs = {
    systems.url = "github:nix-systems/default";
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/DeterminateSystems/nixpkgs-weekly/*";
    flake-parts.url = "github:hercules-ci/flake-parts";

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

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
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
      caelestia-shell.homeManagerModules.default
    ];

    nixosModules = path:
      with inputs; [
        (path + "/default.nix")
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
            extraSpecialArgs = {inherit inputs self;};
            sharedModules = homeManagerModules;
          };
        }
      ];

    # --- System Builders --- #

    # Base NixOS System Builder
    mkSystem = _name: path: let
      meta = readMeta path;
      systemArch = meta.system or "x86_64-linux";
    in
      lib.nixosSystem {
        system = systemArch;
        specialArgs = {
          inherit inputs self;
        };
        modules = nixosModules path;
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
      # Extract username from folders named "user@host" or just "user"
      username = lib.head (lib.splitString "@" name);
    in
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {inherit inputs self;};
        modules = with inputs;
          [
            (path + "/default.nix")
            {
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
        treefmt-nix.flakeModule
        git-hooks-nix.flakeModule
        github-actions-nix.flakeModule
      ];

      # Supported systems for devShells/checks
      systems = import inputs.systems;

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit (config) pre-commit;
          };
        };

        packages =
          import ./pkgs {inherit lib pkgs self;};

        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./modules/nixos {inherit lib self;};
        homeModules = import ./modules/home {inherit lib self;};

        # Overlay Exports
        overlays =
          import ./overlays {inherit lib self;}
          // {
            nur = inputs.nur.overlays.default;
          };

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs mkSystem (discover ./systems);

        # All standalone homes in the /homes folder
        homeConfigurations = lib.mapAttrs mkHome (discover ./homes);

        # All templates in the /templates folder
        templates =
          lib.mapAttrs (name: _: let
            path = ./templates + "/${name}";
            meta = readMeta path;
          in {
            inherit path;
            description = meta.description or "A flake template";
          }) (
            lib.filterAttrs (
              name: type: type == "directory" && builtins.pathExists (./templates + "/${name}/default.nix")
            ) (builtins.readDir ./templates)
          );
      };
    };
}
