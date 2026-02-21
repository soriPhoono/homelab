{
  pkgs,
  lib,
  nixtest,
  ...
}: let
  nixtestLib = import (nixtest + "/src/nixtest.nix");

  # We test the module in isolation using evalModules
  eval = lib.evalModules {
    specialArgs = { inherit pkgs; };
    modules = [
      ../modules/nixos/core/networking/netbird.nix
      {
        core.networking.netbird.enable = true;
        # Mock services.netbird options
        options.services.netbird.enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        # Mock networking.firewall options
        options.networking.firewall.checkReversePath = lib.mkOption {
          type = lib.types.anything;
        };
      }
    ];
  };

  assertions = [
    {
      name = "Netbird service is enabled";
      expected = true;
      actual = eval.config.services.netbird.enable;
    }
    {
      name = "Firewall checkReversePath is loose";
      expected = "loose";
      actual = eval.config.networking.firewall.checkReversePath;
    }
  ];

  report = nixtestLib.assertTests (nixtestLib.runTests assertions);
in
  pkgs.runCommand "netbird-test" {} ''
    echo "${report}"
    touch $out
  ''
