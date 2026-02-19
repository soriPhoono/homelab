{
  pkgs,
  lib,
  self,
  ...
}: let
  # Get all defined NixOS configurations
  nixosConfigs = self.nixosConfigurations or {};

  # Map them to a list of { name = ...; path = ...; } for linkFarm
  entries =
    lib.mapAttrsToList (name: config: {
      name = "nixos-${name}";
      path = config.config.system.build.toplevel;
    })
    nixosConfigs;
in
  if (entries == [])
  then
    pkgs.runCommand "nixos-builds-skip" {} ''
      echo "No NixOS configurations found. Skipping."
      touch $out
    ''
  else pkgs.linkFarm "nixos-builds" entries
