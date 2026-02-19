{
  pkgs,
  lib,
  self,
  ...
}: let
  # Get all defined Home Manager configurations
  homeConfigs = self.homeConfigurations or {};

  # Map them to a list of { name = ...; path = ...; } for linkFarm
  entries =
    lib.mapAttrsToList (name: config: {
      name = "home-${name}";
      path = config.activationPackage;
    })
    homeConfigs;
in
  if (entries == [])
  then
    pkgs.runCommand "home-builds-skip" {} ''
      echo "No Home Manager configurations found. Skipping."
      touch $out
    ''
  else pkgs.linkFarm "home-builds" entries
