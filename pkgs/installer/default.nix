{
  self,
  lib,
  inputs,
  pkgs,
  ...
}: let
  nixosModules = with inputs; [
    ./config.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    lanzaboote.nixosModules.lanzaboote
    determinate.nixosModules.default
    nixos-facter-modules.nixosModules.facter
    disko.nixosModules.disko
    comin.nixosModules.comin
    nix-index-database.nixosModules.nix-index

    (_: {
      image.modules.installation-cd-minimal = {
        imports = ["${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
      };

      nixpkgs.overlays = builtins.attrValues self.overlays;
      home-manager = {
        useGlobalPkgs = true;
        startAsUserService = true;
        extraSpecialArgs = {inherit inputs self lib;};
        sharedModules = [
          self.homeModules.default
          sops-nix.homeManagerModules.sops
          nvf.homeManagerModules.default
          mcps.homeManagerModules.gemini-cli
          mcps.homeManagerModules.claude
          mcps.homeManagerModules.antigravity
        ];
        backupFileExtension = "bak";
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
      modules = [self.nixosModules.default] ++ nixosModules;
    })
    .config.system.build.images.iso
    // {
      meta.platforms = lib.platforms.linux;
    }
  else
    pkgs.runCommand "installer-iso-dummy" {} ''
      echo "Installer ISO is only available on Linux." > $out
    ''
