{
  pkgs,
  lib,
  nixtest,
  ...
}: let
  nixtestLib = import (nixtest + "/src/nixtest.nix");
  fixtureDir = ./fixtures/discover;
  result = lib.discover fixtureDir;
  tests = [
    {
      name = "Discover subdirectory with default.nix";
      expected = true;
      actual = result ? subdir;
    }
    {
      name = "Verify path of subdirectory discovery";
      expected = toString (fixtureDir + "/subdir");
      actual = if result ? subdir then toString result.subdir else "";
    }
    {
      name = "Discover regular .nix file";
      expected = true;
      actual = result ? regular;
    }
    {
      name = "Verify path of regular file discovery";
      expected = toString (fixtureDir + "/regular.nix");
      actual = if result ? regular then toString result.regular else "";
    }
    {
      name = "Ignore non-.nix files";
      expected = false;
      actual = result ? ignored;
    }
    {
      name = "Ignore default.nix in root";
      expected = false;
      actual = result ? default;
    }
    {
      name = "Ignore empty directory without default.nix";
      expected = false;
      actual = result ? empty_dir;
    }
  ];
  report = nixtestLib.assertTests (nixtestLib.runTests tests);
in
  pkgs.runCommand "test-lib-discover" {} ''
    echo "Running tests for lib.discover..."
    echo "${report}"
    touch $out
  ''
