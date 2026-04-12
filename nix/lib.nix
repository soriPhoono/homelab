_final: prev: {
  homelab = {
    discover = dir:
      prev.mapAttrs' (name: _: {
        name = prev.removeSuffix ".nix" name;
        value = dir + "/${name}";
      }) (
        prev.filterAttrs (
          name: type:
            (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
            || (type == "regular" && name != "default.nix" && prev.hasSuffix ".nix" name)
        ) (builtins.readDir dir)
      );
  };
}
