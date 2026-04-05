{lib, ...}: let
  modules = lib.discover ./.;
in
  modules
  // {
    default = {
      imports = builtins.attrValues modules;
    };
  }
