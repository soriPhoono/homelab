{lib, ...}: let
  modules = lib.homelab.helpers.core.discover ./.;
in {
  imports = builtins.attrValues modules;
}
