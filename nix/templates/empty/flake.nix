{
  description = "Empty flake with basic devshell";

  inputs = {
    systems.url = "github:nix-systems/default";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    nixtest = {
      url = "github:jetify-com/nixtest";
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
  };

  outputs = inputs @ {
    nixpkgs,
    flake-parts,
    agenix,
    ...
  }: let
    inherit (nixpkgs) lib;
  in
    with lib;
      flake-parts.lib.mkFlake {inherit inputs;} {
        imports = with inputs; [
          agenix-shell.flakeModules.default
          treefmt-nix.flakeModule
          git-hooks-nix.flakeModule
        ];
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
              inherit (config) pre-commit agenix-shell;
            };
          };

          checks = let
            unitTests =
              lib.discoverTests {
                inherit pkgs inputs self;
                inherit (inputs) nixtest;
              }
              ./tests;
          in
            unitTests;

          treefmt = import ./treefmt.nix {
            inherit lib pkgs;
          };
          pre-commit = import ./pre-commit.nix {
            inherit lib pkgs;
          };
        };
      };
}
