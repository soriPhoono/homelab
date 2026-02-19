{
  pkgs,
  lib,
  self,
  ...
}: let
  # Get all defined Droid configurations
  droidConfigs = self.nixOnDroidConfigurations or {};

  # Map them to a list of { name = ...; path = ...; } for linkFarm
  entries =
    lib.mapAttrsToList (name: config: {
      name = "droid-${name}";
      path = config.activationPackage;
    })
    droidConfigs;
in
  if (entries == [])
  then
    pkgs.runCommand "droid-builds-skip" {} ''
      echo "No Nix-on-Droid configurations found. Skipping."
      touch $out
    ''
  else pkgs.linkFarm "droid-builds" entries
