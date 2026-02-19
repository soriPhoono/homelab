{
  self,
  lib,
  inputs,
  pkgs,
  ...
}: let
  homeManagerModules = with inputs; [
    self.homeModules.default
    sops-nix.homeManagerModules.sops
    nvf.homeManagerModules.default
    mcps.homeManagerModules.gemini-cli
    mcps.homeManagerModules.claude
    mcps.homeManagerModules.antigravity
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

    (_: {
      image.modules.installation-cd-minimal = {
        imports = ["${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
      };

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
    })
  ];
in
  if pkgs.stdenv.hostPlatform.system == "x86_64-linux"
  then
    (lib.nixosSystem {
      inherit pkgs;
      specialArgs = {
        inherit inputs self;
        hostName = "installer";
      };
      modules = nixosModules;
    })
    .config.system.build.images.iso
    // {
      meta.platforms = lib.platforms.linux;
    }
  else
    pkgs.runCommand "installer-iso-dummy" {} ''
      echo "Installer ISO is only available on Linux." > $out
    ''
