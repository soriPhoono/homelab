{lib, ...}: let
  modules = lib.homelab.helpers.core.discover ./.;
in
  modules
  // {
    default = {
      imports = builtins.attrValues modules;
    };
  }
