{
  pkgs,
  lib,
  self,
  nixtest,
  ...
}: let
  nixtestLib = import (nixtest + "/src/nixtest.nix");

  # Access the configuration for soriphoono
  # Note: nixOnDroidConfigurations are attrsets of the final configuration
  soriphoonoConfig = self.nixOnDroidConfigurations.soriphoono or null;

  assertions =
    if soriphoonoConfig == null
    then []
    else [
      {
        name = "Soriphoono: Fish shell enabled in Home Manager";
        expected = true;
        actual = soriphoonoConfig.config.home-manager.config.programs.fish.enable;
      }
      {
        name = "Soriphoono: Starship enabled in Home Manager";
        expected = true;
        actual = soriphoonoConfig.config.home-manager.config.programs.starship.enable;
      }
      {
        name = "Soriphoono: Starship Fish integration enabled";
        expected = true;
        actual = soriphoonoConfig.config.home-manager.config.programs.starship.enableFishIntegration;
      }
    ];

  report =
    if soriphoonoConfig == null
    then "Configuration not found"
    else nixtestLib.assertTests (nixtestLib.runTests assertions);
in
  if soriphoonoConfig == null
  then
    pkgs.runCommand "starship-check-skip" {} ''
      echo "Soriphoono configuration not found. Skipping."
      touch $out
    ''
  else
    pkgs.runCommand "starship-check" {} ''
      echo "Checking Starship configuration..."
      echo "${report}"
      touch $out
    ''
