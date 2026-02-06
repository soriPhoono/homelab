{
  lib,
  pkgs,
  self,
  inputs,
  ...
}:
lib.mapAttrs' (
  name: _: {
    name = lib.removeSuffix ".nix" name;
    value = import (./. + "/${name}") {inherit lib pkgs self inputs;};
  }
) (
  lib.filterAttrs (
    name: type:
      (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
      || (type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
  ) (builtins.readDir ./.)
)
