{lib, ...}: let
  # Discover all modules in this directory
  modules =
    lib.mapAttrs' (name: _: {
      name = lib.removeSuffix ".nix" name;
      value = ./. + "/${name}";
    }) (
      lib.filterAttrs (
        name: type:
          type == "directory" && builtins.pathExists (./. + "/${name}/default.nix")
      ) (builtins.readDir ./.)
    );
in
  modules
  // {
    # Entry point that imports all discovered modules
    default = {
      imports = builtins.attrValues modules;
    };
  }
