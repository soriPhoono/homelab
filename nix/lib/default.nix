_: self: _super: {
  discover = dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = dir + "/${name}";
    }) (
      self.filterAttrs (
        name: type:
          (type == "directory" && builtins.pathExists (dir + "/${name}/default.nix"))
          || (type == "regular" && name != "default.nix" && self.hasSuffix ".nix" name && name != "helpers.nix")
      ) (builtins.readDir dir)
    );

  # Discovery for Tests: specifically just find .nix files in tests/
  discoverTests = args: dir:
    self.mapAttrs' (name: _: {
      name = self.removeSuffix ".nix" name;
      value = import (dir + "/${name}") (args // {lib = self;});
    }) (
      self.filterAttrs (
        name: type:
          type == "regular" && self.hasSuffix ".nix" name && name != "helpers.nix"
      ) (builtins.readDir dir)
    );

  # Dynamic Discovery: Reads a directory and returns an attrset of { name = path; }
  # including directories with default.nix and standalone .nix files.
  readMeta = dir:
    if builtins.pathExists (dir + "/meta.json")
    then builtins.fromJSON (builtins.readFile (dir + "/meta.json"))
    else {};
}
