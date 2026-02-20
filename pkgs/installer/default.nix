{
  self,
  lib,
  inputs,
  pkgs,
  ...
}: let
  nixosModules = with inputs; [
    ./config.nix

    (_: {
      image.modules.installation-cd-minimal = {
        imports = ["${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"];
      };

      nixpkgs.overlays = builtins.attrValues self.overlays;
      home-manager.extraSpecialArgs.hostName = "installer";
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
      modules = self.nixosModules.default ++ nixosModules;
    })
    .config.system.build.images.iso
    // {
      meta.platforms = lib.platforms.linux;
    }
  else
    pkgs.runCommand "installer-iso-dummy" {} ''
      echo "Installer ISO is only available on Linux." > $out
    ''
