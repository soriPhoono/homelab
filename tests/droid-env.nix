{
  pkgs,
  lib,
  self,
  nixtest,
  ...
}: let
  nixtestLib = import (nixtest + "/src/nixtest.nix");

  # Iterate over all defined Droid configurations
  droidConfigs = self.nixOnDroidConfigurations or {};

  # For each configuration, run assertions
  assertions = lib.flatten (lib.mapAttrsToList (name: config: let
    hmUsers = config.config.home-manager.users or {};
  in
    [
      {
        name = "Droid '${name}': Activation package exists";
        expected = true;
        actual = config ? activationPackage || config.config.build ? activationPackage;
      }
      {
        name = "Droid '${name}': Home Manager is enabled";
        expected = true;
        actual = config.config.home-manager.useGlobalPkgs or false;
      }
    ]
    ++ (lib.flatten (lib.mapAttrsToList (userName: userConfig: [
        {
          name = "Droid '${name}' User '${userName}': Fastfetch is disabled";
          expected = false;
          actual = userConfig.programs.fastfetch.enable or false;
        }
      ])
      hmUsers)))
  droidConfigs);

  report = nixtestLib.assertTests (nixtestLib.runTests assertions);
in
  if (droidConfigs == {})
  then
    pkgs.runCommand "droid-env-check-skip" {} ''
      echo "No Nix-on-Droid configurations found. Skipping."
      touch $out
    ''
  else
    pkgs.runCommand "droid-env-check" {} ''
      echo "Checking Nix-on-Droid environments..."
      echo "${report}"
      touch $out
    ''
