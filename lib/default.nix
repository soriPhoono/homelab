_: self: _super: {
  # Dynamic Discovery: Reads a directory and returns an attrset of { name = path; }
  # including directories with default.nix and standalone .nix files.
  discover = dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = dir + "/${name}";
    }) (
      self.filterAttrs (
        name: type:
          (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
          || (type == "regular" && name != "default.nix" && self.hasSuffix ".nix" name)
      ) (builtins.readDir dir)
    );

  # Discovery for Tests: specifically just find .nix files in tests/
  discoverTests = args: dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = import (dir + "/${name}") args;
    }) (
      self.filterAttrs (
        name: type:
          type == "regular" && self.hasSuffix ".nix" name
      ) (builtins.readDir dir)
    );

  # Metadata Reader: Reads meta.json from a path
  readMeta = path:
    if builtins.pathExists (path + "/meta.json")
    then builtins.fromJSON (builtins.readFile (path + "/meta.json"))
    else {};
}
