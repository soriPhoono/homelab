{
  lib,
  pkgs,
  self,
  ...
}:
lib.mapAttrs (
  name: _: import ./. + "/${name}" {inherit lib pkgs self;}
) (
  lib.filterAttrs (
    name: type:
      (type == "directory" && builtins.pathExists (./. + "/${name}/default.nix"))
      || (type == "regular" && name != "default.nix" && lib.hasSuffix ".nix" name)
  ) (builtins.readDir ./.)
)
