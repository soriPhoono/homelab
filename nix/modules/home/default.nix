{lib, ...}: let
  modules = lib.homelab.core.discover ./.;
in
  modules
  // {
    default = {
      imports = builtins.attrValues modules ++ [./desktop];
    };
  }
