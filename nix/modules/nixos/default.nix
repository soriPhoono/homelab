{lib, ...}: let
  modules = lib.homelab.discover ./.;
in
  modules
  // {
    default = {
      imports = builtins.attrValues modules;
    };
  }
