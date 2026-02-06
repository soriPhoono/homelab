{
  self,
  lib,
  inputs,
  ...
}: let
  # Metadata Reader
  readMeta = path:
    if builtins.pathExists (path + "/meta.json")
    then builtins.fromJSON (builtins.readFile (path + "/meta.json"))
    else {};

  meta = readMeta ./.;
  systemArch = meta.system or "x86_64-linux";

  homeManagerModules = with inputs; [
    self.homeModules.default
    sops-nix.homeManagerModules.sops
    nvf.homeManagerModules.default
    caelestia-shell.homeManagerModules.default
  ];

  nixosModules = with inputs; [
    ./config.nix

    self.nixosModules.default

    home-manager.nixosModules.home-manager
    nixos-facter-modules.nixosModules.facter
    disko.nixosModules.disko
    determinate.nixosModules.default
    lanzaboote.nixosModules.lanzaboote
    sops-nix.nixosModules.sops
    comin.nixosModules.comin
    nix-index-database.nixosModules.nix-index

    # Required for ISO production
    "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"

    {
      nixpkgs.overlays = builtins.attrValues self.overlays;
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit inputs self;
          hostName = "installer";
        };
        sharedModules = homeManagerModules;
      };
    }
  ];
in
  (lib.nixosSystem {
    system = systemArch;
    specialArgs = {
      inherit inputs self;
      hostName = "installer";
    };
    modules = nixosModules;
  })
  .config.system.build.images.iso
