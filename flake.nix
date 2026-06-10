{
  description = "A system flake for my homelab and personal devices";

  inputs = {
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    templates.url = "github:soriPhoono/templates";

    determinate = {
      url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
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

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
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
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-skills = {
      url = "github:sudosubin/nix-skills";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-parts,
    nur,
    nix-skills,
    ...
  }: let
    readMeta = dir:
      if builtins.pathExists (dir + "/meta.json")
      then builtins.fromJSON (builtins.readFile (dir + "/meta.json"))
      else {};

    lib = nixpkgs.lib.extend (import ./nix/lib.nix);

    # --- System Support & Package Cache --- #
    systems = import inputs.systems;

    pkgsBatch = lib.genAttrs systems (
      system: let
        basePkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            permittedInsecurePackages = [
              "electron-39.8.10"
            ];
          };
          overlays = builtins.attrValues (
            import ./nix/overlays {inherit inputs lib;}
            // {
              nur = nur.overlays.default;
              nix-skills = nix-skills.overlays.default;
            }
          );
        };
      in
        basePkgs // {inherit lib;}
    );

    # --- System Builder Parameters --- #
    homeManagerModules = with inputs; [
      self.homeModules.default
      sops-nix.homeManagerModules.sops
      stylix.homeModules.stylix
      noctalia.homeModules.default
    ];

    nixosModules = with inputs; [
      self.nixosModules.default
      disko.nixosModules.disko
      determinate.nixosModules.default
      comin.nixosModules.comin
      sops-nix.nixosModules.sops
      stylix.nixosModules.stylix
      jovian.nixosModules.default
      nix-index-database.nixosModules.nix-index
      hermes-agent.nixosModules.default
      home-manager.nixosModules.home-manager
    ];

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
              _module.args.lib = lib;
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
                sharedModules =
                  homeManagerModules
                  ++ [
                    {
                      # suppress stylix home-module nixpkgs.overlays when
                      # useGlobalPkgs is enabled; they are already applied
                      # at the NixOS layer and would trigger a deprecation
                      # warning (soon to be an error) in home-manager.
                      stylix.overlays.enable = false;
                    }
                  ];
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
        # --- Package Cache --- #
        _module.args.pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            # mcp-nixos transitively depends on arrow-cpp which is marked broken on
            # x86_64-darwin.  Since we only deploy NixOS systems (Linux), this is
            # safe to allow — the package simply won't build on unsupported platforms
            # but won't crash evaluation either.
            allowBroken = true;
          };
        };

        # --- Configuration Builders --- #
        githubActions = import ./actions.nix {inherit self lib;};
        treefmt = import ./treefmt.nix {inherit lib pkgs;};
        pre-commit = import ./pre-commit.nix {inherit lib pkgs;};

        # --- Development Shells & Checks --- #
        devShells.default = import ./shell.nix {
          inherit lib pkgs;
          config = {
            inherit
              (config)
              pre-commit
              agenix-shell
              githubActions
              ;
          };
        };

        # --- Packages and applications --- #
        apps = rec {
          install = {
            type = "app";
            program = pkgs.writeShellApplication {
              name = "install.sh";
              runtimeInputs = with pkgs; [
                disko
              ];
              text = ''
                target=$1

                nix run .#writeDisks -- $target

                sudo nixos-install --flake .#$target --option max-jobs 1 --option cores 4
              '';
            };
          };
          writeDisks = {
            type = "app";
            program = pkgs.writeShellApplication {
              name = "write-disk-config.sh";
              runtimeInputs = with pkgs; [
                disko
              ];
              text = ''
                target=$1

                sudo disko -m destroy,format,mount --flake .#$target
              '';
            };
          };
          default = install;
        };
      };

      flake = {
        # Global Module Exports
        nixosModules = import ./nix/modules/nixos {inherit lib self;};
        homeModules = import ./nix/modules/home {inherit lib self;};

        # --- Automatic Discovery & Construction --- #

        # All systems in the /systems folder
        nixosConfigurations = lib.mapAttrs (hostName: _: mkSystem hostName) (
          lib.homelab.core.discover ./nix/systems
        );

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
            builtins.filter (x: x != null) (lib.mapAttrsToList processHomeDir homesContent)
          );
      };
    };
}
