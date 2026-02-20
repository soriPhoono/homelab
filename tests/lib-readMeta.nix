{
  pkgs,
  lib,
  nixtest,
  ...
}: let
  nixtestLib = import (nixtest + "/src/nixtest.nix");

  assertions = [
    {
      name = "readMeta reads valid json";
      expected = {test = "value";};
      actual = lib.readMeta ./fixtures/readMeta/valid;
    }
    {
      name = "readMeta returns empty for directory without meta.json";
      expected = {};
      actual = lib.readMeta ./fixtures/readMeta/invalid;
    }
  ];

  report = nixtestLib.assertTests (nixtestLib.runTests assertions);
in
  pkgs.runCommand "test-lib-readMeta" {} ''
    echo "${report}"
    touch $out
  ''
