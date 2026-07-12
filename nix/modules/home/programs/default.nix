{lib, ...}: let
  modules = lib.homelab.core.discover ./.;
in {
  imports = builtins.attrValues modules;
}
